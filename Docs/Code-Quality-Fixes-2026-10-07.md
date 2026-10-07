# 代码质量报告：第一批修复（2026-10-07）

依据桌面的 Pitchee_iOS_Code_Quality_Report.md，本轮处理 P0 音频生命周期及本地化缺失，同时补充相关对象的释放清理。未更改 SwiftData 持久化字段、评分公式或原生模型。

## 已实现

- **系统中断**：录音路径监听来电等会话中断、输入设备接入/拔出、无适用音频路由和媒体服务重置。忽略自身的 category change 和 interruption ended；不会自动恢复麦克风。
- **离页和后台**：切出 Practice Tab、导航返回、ScoringView 消失或进入后台均结束当前录音。系统麦克风权限弹窗造成的短暂 inactive 不取消授权；授权完成后等待 active 再启动，真正进入后台仍取消请求。
- **已录内容保全**：已经创建的采集安全停止，排空已接受的写入后再分析 WAV。后台只完成收尾，回到前台后才开始读取受保护的文件。iOS 收尾申请短暂后台任务并在写入结束后释放。结果页显示录音中断提示；写入失败明确报错，损坏文件在关闭后清理。
- **租约恢复**：协调器弱引用持有者，下一次激活可立即回收无主租约。存活的录音，以及正在收尾的采集继续保持排他权。这里采用持有者生命周期检测，而非超时强制收回：长时间写盘并不能证明录音已经失活。旧请求的完成、取消或清理不能释放新请求的租约。
- **释放清理**：PracticePlayback 和 PianoSoundEngine 释放时停止引擎/播放器并注销租约；MonitorViewModel 释放时移除通知观察者并安排音频收尾。回放代理用每次操作的 generation 校验完成通知，避免向 MainActor 传递非 Sendable 的 AVAudioPlayer。
- **本地化**：补齐 settings.personalization.sectionTitle 缺失的 26 个语言；新增中断提示覆盖工程全部 29 个语言。非中英文翻译保持 needs_review 状态。

## 验证

新增 Scripts/test-recording-lifecycle.sh：

- 协调器 **25 项**：录音/钢琴/回放无主租约恢复、重复释放、存活录音保护、收尾持有者转移、回放交接、激活失败、旧激活完成。
- 录音状态机 **35 项**：编译生产 AnalysisViewModel、RecordingAssessment 和 PracticePlayback，使用可控制的麦克风、系统通知及推理替身和内存 SwiftData 容器。覆盖权限弹窗、授权拒绝、后台取消、旧请求晚到、系统通知、WAV 保留、前台恢复分析、启动中断、释放期间收尾、写盘失败及失败后再次录音。测试不读取或写入用户的研究数据、诊断或历史。
- 新增脚本以完整严格并发检查、warnings-as-errors 编译通过。

原有验证：

- test-live-f0.sh：155 项，0 失败，使用实际 Core 模型及采集管线。
- test-monitor-capture.sh：44 项，0 失败。
- test-practice.sh：37 项、旧库迁移及重复打开、5 项录音质量音频检查通过。
- test-localizations.sh：词条/语言/格式参数校验、Python 回归测试、全部 29 个语言的 Swift 运行时检查通过。
- 完整 Debug / Release iOS Simulator 构建及 git diff --check 通过。

独立 macOS 采集脚本仍有原先的 CoreAnalyzer 非 Sendable 句柄 deinit 警告和 macOS 27 installTap 弃用提示。App 构建有无 AppIntents 依赖的元数据提示。这些不属于本轮已修复事项。

## 后续范围

报告中的其余 P1/P2 尚未实施：死代码及测试描述符迁移、Core C ABI 异常兜底、知识库单源和异步加载、Core 句柄隔离/采集释放兜底、评分入口合并、实时回调缓冲架构及声谱/FFT 优化。

本轮没有真机麦克风/蓝牙/来电实验。自动化检查确认状态机、WAV 保留和租约时序，不能替代真机对锁屏文件保护、系统中断通知和后台时间额度的验证。
