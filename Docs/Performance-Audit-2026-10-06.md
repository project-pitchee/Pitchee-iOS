# Pitchee 性能热点审计 · 2026-10-06

本轮使用 Instruments Time Profiler、Release 原生微基准和 SwiftUI 代码审计。当前最值得继续优化的是 **ECAPA 离线推理、实时 F0 的重叠窗口计算，以及 Monitor 的初始化与刷新频率**。

审计过程中工作区发生了并行修改。下文将当前仍存在的问题、修改前的实验和已被新代码处理的问题分别标明。本轮审计没有修改业务源码；产物是本报告、基准源码、原始结果、trace 和解析脚本。

## 测量范围和版本边界

- 主机：Apple M5、24 GiB、macOS 27.2；Xcode / Instruments 27.1。
- App：以本轮构建时的未提交工作区生成 Release，构建成功。在独立 iPhone 17 / iOS 27.0 模拟器采集启动，以及首页 → Practice → 空白音高监测页的导航。
- 原生：实际集成的 `Dependencies/PitcheeCore`，而非旁边独立的 Core 仓库；CMake Release `-O3`，2 个 intra-op 线程，`use_coreml=1`。Core HEAD 为 `e84d9c9a22401f5f25504a2e4348e50ed2db00bf`。本轮结束复核时其推理实现未发生修改。
- 全部算法输入为确定性合成 PCM，没有使用真实用户录音。未完成真机采样，未开启模拟器麦克风；因此没有实际录音链、长时间监听、热降频或真实历史滚动的端到端性能结论。
- 初步基准期间有其他构建和应用活动，观测到内存压力及约 2.56 GiB swap。绝对墙时是本机探索性观测，不能直接作为 iPhone 时延或功耗预算。原生工作负载尽快运行，没有实时节拍，CPU 时间也包含线程协调与等待时自旋。
- App trace 对应构建时的版本，不包含之后并行修改的 Swift 文件。最新文件仅做静态复核，没有把旧 trace 当作新版本的回归验证。

证据目录：[.build/performance-audit-20261006](/Users/dannyfeng/Documents/Pitchee/.build/performance-audit-20261006)。当前源码哈希与版本边界见 [audit-manifest.json](/Users/dannyfeng/Documents/Pitchee/.build/performance-audit-20261006/audit-manifest.json)。

## 当前仍存在的热点

### 1. ECAPA 编码器占据绝大部分离线分析时间

**证据等级：原生完整流程实测 + Instruments 调用栈。**

20 秒合成元音通过 VAD 并成功完成分析。在单独的 Time Profiler 运行中，总分析墙时为 **34.917 秒**，embedding 阶段为 **33.762 秒，约 96.7%**。较早不带 Instruments 的探索性运行中，总计 28.350 秒，embedding 为 26.872 秒，约 94.8%。两个运行的绝对时长受负载影响，但主要阶段一致。

离线 trace 共 39,218 个目标进程 CPU 样本：

| 符号 | 样本占比 | 统计口径 |
| --- | ---: | --- |
| `MlasSgemmOperation` | 76.39% | inclusive，包含子调用 |
| `MlasConvGemmDirectThreaded` | 72.72% | inclusive，与上一行重叠 |
| `.LAdd.Compute16.x4.BlockBy4Loop` | 59.74% | exclusive，采样叶子 |

这说明优化重点应放在模型卷积/矩阵乘法及其执行器。不是 SwiftUI 展示结果的成本，也不是 JSON 编码主导。当前配置使用 1.515 秒窗口、100 ms 步长、batch 8；20 秒输入产生 186 个 VFP 窗口，约 24 批。自然度阶段已经复用 embeddings，不需要再建议消除一个不存在的第二次 ECAPA 推理。

位置：[analyzer.cpp:182](/Users/dannyfeng/Documents/Pitchee/Dependencies/PitcheeCore/src/analyzer.cpp:182)、[internal.hpp:13](/Users/dannyfeng/Documents/Pitchee/Dependencies/PitcheeCore/src/internal.hpp:13)。

本机日志显示 ECAPA 的 406 个节点中只有 3 个被 Core ML provider 支持。这个覆盖率只适用于本次 macOS 配置；`use_coreml=1` 不能证明整张网络已通过硬件加速执行。

**建议：**首先在目标 iPhone 上检查逐节点执行器分配及相同音频的阶段耗时；评估 ECAPA 的 Core ML 转换、支持的算子/数据布局和 batch 策略。量化、模型替换或窗口步长调整必须附带分数与模型精度验证，不能只比较速度。

原始证据：[native-offline.trace](/Users/dannyfeng/Documents/Pitchee/.build/performance-audit-20261006/native-offline.trace)、[采样摘要](/Users/dannyfeng/Documents/Pitchee/.build/performance-audit-20261006/native-offline-summary.md)、[进度及耗时日志](/Users/dannyfeng/Documents/Pitchee/.build/performance-audit-20261006/native-offline-profile.jsonl)。

### 2. 实时 F0 按输入批次反复计算完整 320 ms 上下文

**证据等级：当前源码 + 原生实时微基准 + Instruments。**

默认 context 为 5,120 个 16 kHz 样本，即 320 ms；最小 hop 为 256 个样本，即 16 ms。满足 hop 后重新对完整 context 运行 `analyze_pitch`，然后过滤已输出的时间戳。当前录音链虽然增加了有界队列，仍然对每次转换后的 PCM 调用推理；200 ms 合并只发生在推理之后，限制的是 UI 交付。

位置：[analyzer.cpp:833](/Users/dannyfeng/Documents/Pitchee/Dependencies/PitcheeCore/src/analyzer.cpp:833)、[完整窗口推理:901](/Users/dannyfeng/Documents/Pitchee/Dependencies/PitcheeCore/src/analyzer.cpp:901)、[录音处理与 UI 合并:332](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Audio/LivePitchAudioCapture.swift:332)、[Monitor 每批推理:55](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorAudioCapture.swift:55)。

固定输入 chunk 341（约等于 48 kHz 下 1024 帧重采样后的大小）的确定性实验中，约 30 秒音频触发 **1,407 次调用**，发出 **2,814 帧，约 93.84 帧/秒**。真实重采样可能在 341/342 等大小间变化，本实验没有复现实际设备的 tap 尺寸分布。

| 探索性微基准 | chunk 341 | chunk 1600 / 100 ms |
| --- | ---: | ---: |
| 合成音：CPU 秒 / 音频秒 | 0.452 | 0.094 |
| 静音：CPU 秒 / 音频秒 | 0.486 | 0.115 |
| 约 30 秒音频的调用次数 | 1,407 | 300 |

减少调用频率的实验显示了较大的优化空间，但不是已应用到 App 的收益。延迟、短音捕获、voicing 和时间戳网格都要单独验证。不同 chunk 会移动窗口局部时间网格，导致输出帧数变化，不能只比较吞吐。

实时 trace 的 18,280 个 CPU 样本中，`MlasConvIm2Col` exclusive 占 12.29%，`WorkerLoop` exclusive 占 22.35%，明确的 `SpinPause` exclusive 占 3.94%。`WorkerLoop` 也执行有效计算，不能把它的整条 inclusive 栈都称为无效自旋。

**建议：**在 Core 层验证固定全局时间网格、适当批量推理或真正增量推理；以可接受的 UI 延迟为约束。另对比 1/2 线程和 ORT 自旋设置。不要先优化 Swift 数组的细小分配，却保留高频完整窗口推理。

原始证据：[native-live.trace](/Users/dannyfeng/Documents/Pitchee/.build/performance-audit-20261006/native-live.trace)、[采样摘要](/Users/dannyfeng/Documents/Pitchee/.build/performance-audit-20261006/native-live-summary.md)、[基准结果与限制](/Users/dannyfeng/Documents/Pitchee/.build/performance-audit-20261006/native-bench/README.md)。

### 3. 纯音高监测加载整套六个模型，并在离开后释放

**证据等级：当前源码 + 初始化微基准；没有真机启动耗时。**

`MonitorViewModel` 的 pitch 分支创建完整 `PitcheeCoreAnalyzer`。原生构造依次装载 ECAPAFrontend、ECAPA、VFPHead、SwiftF0、SileroVAD 和 Naturalness，而实时接口只使用 SwiftF0。离开页面时 `analyzer = nil`，下一次开始音高监测又需要创建。

探索性完整 analyzer 连续三次创建为 **1,099 / 604 / 337 ms**。稍后单独加载已热缓存的 SwiftF0 为 3.26 ms；两组缓存条件不同，不能把比值解释成冷启动提速倍数。

位置：[MonitorViewModel.swift:129](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViewModel.swift:129)、[释放:329](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViewModel.swift:329)、[六模型创建:401](/Users/dannyfeng/Documents/Pitchee/Dependencies/PitcheeCore/src/analyzer.cpp:401)。

**建议：**提供仅加载 SwiftF0 的实时 Core 接口，按需加载离线模型；在明确的资源生命周期内复用实时模型。录音分析页面已有复用机制，不应被描述为每次录音都重载全部模型。

### 4. Monitor 启动引擎仍同步发生在主线程

**证据等级：当前源码确认线程归属，尚未测得该操作的卡顿时长。**

`MonitorViewModel` 是 `@MainActor`，其 Task 直接调用同步 `newCapture.start`，内部执行转换器初始化、FFT setup、installTap、`AVAudioEngine.prepare/start`。模型加载已通过 `Task.detached`，但音频引擎启动尚未移出主线程。

位置：[MonitorViewModel.swift:153](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViewModel.swift:153)、[MonitorAudioCapture.swift:29](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorAudioCapture.swift:29)、[引擎启动:80](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorAudioCapture.swift:80)。

**建议：**采用明确的后台串行生命周期队列完成引擎启动/停止，只将状态变更发回 MainActor；保留已有 generation 检查与取消语义。用真机首次开始、暂停后恢复、离页取消三个场景核对启动延迟及主线程阻塞。

### 5. Monitor 状态按每个 buffer 更新；pitch 模式仍执行未使用的 FFT

**证据等级：当前源码确认重复工作；其实际 CPU 占比未实测。**

worker 每批 PCM 都执行 `spectrum.process`，并 await `onUpdate`。主线程每批追加 timeline、更新 cursor。FFT 本身只产生 10 Hz 的频谱帧，但即使没有新频谱帧，状态更新仍按输入 buffer 发生。若 tap 实际为 1024 帧 / 48 kHz，则约 46.9 批/秒；真实设备实际回调频率需要采集，SwiftUI 也可能合并更新。

pitch 页面只显示音高，却仍计算并保存频谱。60 秒数值载荷约 `600 × 1025 × 4 = 2.46 MB`，另有数组元数据。FFT setup 和 scratch buffers 已复用，这里应消除未使用工作，而非重复建议缓存 setup。

可见音高数组每次读取还会复制窗口，读数再求 min/max，图表和空态另行读取。回放时约 30 Hz 更新 cursor，固定曲线与游标尚未拆开；这些是需要后续 trace 定量的候选。

位置：[MonitorAudioCapture.swift:52](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorAudioCapture.swift:52)、[逐批主线程更新:336](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViewModel.swift:336)、[visiblePitchSamples:73](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViewModel.swift:73)、[读数:128](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViews.swift:128)。

**建议：**按监测类型启用 FFT；把完整 PCM 留在有界音频存储中，把 UI 展示快照以 5–10 Hz 等可接受频率发布；每次显示周期共享窗口统计，回放时分离固定曲线和移动游标。调低 UI 更新频率不应丢失 PCM 或压缩音频时间轴。

## 审计中已经发生变化的问题

以下工作区改动不是本审计写入的。当前静态复核确认结构已改变，但没有新的 App trace 来证明最终帧率。

1. **趋势详情重复聚合已移出点循环。** 旧版 getter 模型在 30 天数据时求值 samples 95/126 次，单次 pass 为 112/190 ms；它只代表旧代码的手工调用模型，不是实际 SwiftUI 帧耗时。当前 [InsightsDetailViews.swift:231](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:231) 在父 body 构建一次快照，选择状态下移至子卡片，最近点每次子 body 计算一次，Marks 只读存储字段。原二次放大调用链已静态移除。
2. **历史列表按天重复全表扫描已改成一次分组。** 当前 [InsightsDetailViews.swift:102](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:102) 预先筛选并构建 Dictionary。
3. **分数摘要与文章派生数据增加了缓存。** `RecordingAssessment` / `VoiceScoring` / `InsightsData` 的版本已变化；Practice 搜索、分类和文章解析也有新缓存。旧基准不能表述为当前缓存实现的实测。
4. **录音流已增加有界预算和异步结束。** 当前 [LivePitchAudioCapture.swift:126](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Audio/LivePitchAudioCapture.swift:126) 的 `finish/cancel` 把 teardown 放到后台，raw/pitch 有各自的容量限制。因此旧“无界录音队列、主线程同步排空”的风险不能继续列为当前问题。完整回归测试不在本轮审计中确认。

旧基准源、哈希和 CSV 保留在 [ui-bench/README.md](/Users/dannyfeng/Documents/Pitchee/.build/performance-audit-20261006/ui-bench/README.md)。其中实验 snapshot 是手写标量对照，不是当前 `InsightsMetricChartData` 的性能测试，更不是整个 App 的提速比。

## App trace 的结论与限制

| 场景 | CPU 样本数 | 可支持的结论 |
| --- | ---: | --- |
| Release 模拟器启动、空历史停留 | 7,642 | `dyld4::prepareSim` inclusive 占 74.61%；主要是模拟器装载阶段，不能归因给业务模型加载 |
| 首页 → Practice → 空白音高页 | 3,482 | 本次导航未开始录音；Swift 协议一致性检查占较多样本，需要进一步调用者归因，不能据此下业务优化结论 |
| 原生实时 F0 | 18,280 | 卷积和线程协调明显；不是 App UI 主线程 trace |
| 原生离线分析 | 39,218 | MLAS 卷积/矩阵乘法主导，与 embedding 阶段计时相符 |

上述四份导出的 potential-hangs / hang-risks 表均为 0 行。这只描述对应采样范围和阈值，不代表所有页面不存在卡顿。Time Profiler inclusive 数字会重叠；权重之和是跨线程 CPU 采样权重，不是操作墙时。启动 trace 中 56.42% 的叶子帧没有完整符号，多属 dyld_sim。

App 启动和导航录制均提示一个 table 缺少已知输入源；CPU 采样表已实际导出并检查，不能因此把没有记录的其他指标当成零。

## 证据和复现

- [App 启动 trace](/Users/dannyfeng/Documents/Pitchee/.build/performance-audit-20261006/app-launch-release-v2.trace) / [摘要](/Users/dannyfeng/Documents/Pitchee/.build/performance-audit-20261006/app-launch-summary.md)
- [App 导航 trace](/Users/dannyfeng/Documents/Pitchee/.build/performance-audit-20261006/app-navigation-release.trace) / [摘要](/Users/dannyfeng/Documents/Pitchee/.build/performance-audit-20261006/app-navigation-summary.md)
- [原生实时 trace](/Users/dannyfeng/Documents/Pitchee/.build/performance-audit-20261006/native-live.trace)
- [原生离线 trace](/Users/dannyfeng/Documents/Pitchee/.build/performance-audit-20261006/native-offline.trace)
- [原生基准说明](/Users/dannyfeng/Documents/Pitchee/.build/performance-audit-20261006/native-bench/README.md) / [源代码](/Users/dannyfeng/Documents/Pitchee/.build/performance-audit-20261006/native-bench/bench.cpp)
- [Instruments XML 解析脚本](/Users/dannyfeng/Documents/Pitchee/.build/performance-audit-20261006/analyze_trace.py)
- [Release 构建日志](/Users/dannyfeng/Documents/Pitchee/.build/performance-audit-20261006/build.log)

原生短场景可分别运行 `bench <models绝对路径> 1 live-only` 和 `bench <models绝对路径> 1 offline-only`；完整命令见基准说明。此次创建的独立模拟器已关闭，保留构建和 trace 供复查。

建议处理顺序：先确认并优化 ECAPA 执行器与模型计算，再处理实时 F0 的调用频率/时间网格，随后完成轻量实时模型加载和 Monitor 生命周期、显示快照拆分。当前版本的真机采样应覆盖录音开始/停止、30 秒以上监听、暂停回放及有真实数量历史的图表交互。
