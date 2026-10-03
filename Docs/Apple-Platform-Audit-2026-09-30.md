**Pitchee Apple 平台代码与产品质量审查 · 2026-09-30**

审查结论：项目具备较好的原生实现基础，但尚不能认定为已完整满足 Apple 的发布要求和设计建议。主要问题集中在隐私申报、共享音频会话、系统中断处理、本地化和部分结果页面。格式、架构选择、HIG 建议与 App Store 的明确要求应分别判断。

审查对象是 `/Users/dannyfeng/Documents/Pitchee` 中的 iOS 应用，以及该 Target 实际编译的 `Dependencies/PitcheeCore`。不包含 Android 工程，也不把相邻的独立 Core 工作区当成应用实际依赖。最终源码副本固定于 **2026-09-30 20:08:35（Asia/Shanghai）**，基础提交为 `f8ed325507df85335541d53b93eb35fa184062fb`，包含当时未提交的修改。覆盖 38 个应用 Swift 文件、9,171 行 Swift、2,691 行原生核心源码/头文件、Xcode 配置、资源、本地化、现有测试与第三方依赖集成。源码在审查期间持续变化，因此以证据目录中的 SHA-256 清单界定结论边界。

本次仅增加审查文档和证据，没有修改应用实现或构建配置。部分早期构建错误被工作区后续修改修复，已重新验证，不列入最终待修复问题。

固定副本共记录 **13 项问题：4 项 P1、9 项 P2**。交付前的有限复核发现，工作区后续修改已经修正 A05 的两处动态本地化键构造；该项保留为快照发现，不再标记为当前待修复。新增练习功能等后续变更未纳入本次完整构建与审查，不能把固定副本的通过记录用于这些新代码。

下文代码行号来自固定副本，工作区链接用于定位文件，后续修改可能使行号变化。可复核的带行号源码摘录保存在 [snapshot-code-excerpts.md](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/snapshot-code-excerpts.md)。

**已验证的基础**

- 主流程采用 SwiftUI 的 `NavigationStack`、`TabView`、`Form`、系统分享/文件导出和按需权限请求。麦克风与仅添加照片权限均有用途说明。
- Core 分析由 actor 串行管理；模型加载和音量分析离开主线程。原生对象释放与输出字符串释放有明确所有权。
- 使用语义化持久化键、SwiftData、迁移逻辑和本地诊断数据校验。音频分析完成后尝试删除临时 WAV；诊断与评分对照默认关闭，具有配额、过期、撤回和过期任务隔离。
- 最终副本已包含较多无障碍支持：大字纵向布局、菜单式范围选择、图表描述与文本快照、控件标签、输入标签、减少动态效果、减少透明度、Assistive Access 兼容包装、文本报告导出。
- 使用系统语义颜色和旧系统回退分支。不能仅因没有全面切换到 `@Observable`、Swift 6 或某种 MVVM 目录结构，就判定不符合 Apple 规范。

**验证记录**

| 项目 | 结果与范围 |
| --- | --- |
| 工具链 | Xcode 27.1（27A9269），Apple Swift 6.4；应用语言模式 Swift 5，最低部署 iOS 17 |
| Debug 模拟器构建 | 通过；arm64，关闭签名及字符串提取，不改部署目标 |
| Xcode Analyze | 通过；未发现应用源码诊断。此结果不等同于证明 Swift 并发、所有运行时路径或闭源依赖无缺陷 |
| Release iPhoneOS 构建 | 通过；arm64，关闭签名及字符串提取，不改部署目标。没有执行签名归档或 App Store Connect 验证 |
| 历史与趋势 | 53 项检查通过 |
| 实时 F0 | 54 项检查通过，覆盖多采样率、声道转换、静音与重置 |
| 本地诊断与存储 | 45 项检查通过 |
| 本地评分对照 | 59 项检查通过 |
| 音高图与时间轴 | 最终副本 22 项检查通过 |
| 评分一致性 | 10,742 项检查通过，覆盖 1,530 组真实 C++ 参考数据 |
| C/C++ 核心 CTest | 6/6 通过，包含 WAV、重采样、JSON、频谱与 C ABI |
| Swift 格式检查 | 使用 Apple 工具链 `swift-format`，将缩进设为现有工程的 4 空格后仍有 1,273 条提示；这些不是 1,273 个功能缺陷，也不是 App Store 拒审条件 |
| 本地化语义探针 | 复现了直接插值构造 `LocalizedStringKey` 产生格式键的问题，见 A05 |
| 模拟器显示 | 独立 iPhone Duo / iOS 27.1 测试实例；英文引导页、日语最大辅助字号趋势首页已截图核对，未执行全流程交互或完整无障碍审计 |

所有六组 Swift 脚本合计 11,075 项检查。编译器还给出过无 AppIntents 依赖导致跳过元数据提取的工具提示；应用未使用 App Intents，这不构成缺陷。实时测试中的 ONNX Core ML 分区回退提示也不能直接解释为推理错误。

P1 表示发布前或核心流程应优先修复；P2 表示用户可见缺陷或重要的平台体验问题。下列“代码确认”表示实现和触发条件可由源码确定；涉及系统电话、实际音频路由或压力阈值的结果仍需要真机复现。

**A01 · P1 · 缺少应用自己的 Required Reason API 隐私声明（Apple 明确要求，已核对构建产物）**

应用代码使用 `UserDefaults` / `@AppStorage`，并在分析计时和本地对照中读取 `ProcessInfo.systemUptime`。构建产物只有 MathJaxSwift 资源 bundle 自带的隐私清单，而且其 `NSPrivacyAccessedAPITypes` 为空；应用根 bundle 中没有 `PrivacyInfo.xcprivacy`。第三方资源 bundle 的空清单无法代替应用自己的声明。

证据：[AppStorage.swift:41](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/AppStorage.swift:41)、[AnalysisViewModel.swift:307](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/AnalysisViewModel.swift:307)、[LocalScoreStudyStore.swift:36](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Diagnostics/LocalScoreStudyStore.swift:36)。

修复：为应用 Target 添加并打包清单，按实际使用声明 `NSPrivacyAccessedAPICategoryUserDefaults` 和 `NSPrivacyAccessedAPICategorySystemBootTime`；当前用途可评估 `CA92.1`、`35F9.1`，不能不核实用途就复制全部原因。另对静态 ONNX Runtime 的实际 API 使用进行依赖级核查。验证归档中清单位置和 Xcode 隐私报告。

依据：[Required Reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)、[Privacy manifest](https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk)。Apple 明确说明，使用此类 API 而未声明理由的提交不被 App Store Connect 接受。

**A02 · P1 · 录音和琴键争用同一个音频会话（核心行为，代码确认）**

录音启动把共享 `AVAudioSession` 设置成 `.record / .measurement`；琴键页面出现时又会运行 `prepare()`，把同一会话改成 `.playback`。录音中允许切换到琴键，且底部录音控件仍可见。因此“开始录音 → 打开琴键”会进入录音引擎仍认为正在录音、会话却已改成仅播放的状态；从琴键页启动录音也会反向影响播放。把设置调用放在串行队列上，只能保证调用顺序，不能保证两个功能的会话需求兼容。

证据：[AnalysisViewModel.swift:150](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/AnalysisViewModel.swift:150)、[PianoSoundEngine.swift:102](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Audio/PianoSoundEngine.swift:102)、[ContentView.swift:719](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:719)、[AudioSessionController.swift:21](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Audio/AudioSessionController.swift:21)。

修复：明确是否允许录音与参考音同时工作。若允许，统一协调 `.playAndRecord`、输出路由和引擎重配置；若不允许，在功能层互斥并提示用户。集中管理会话使用者和停用时机，避免一个功能结束后停用另一个功能仍在使用的会话。真机验证往返切换、扬声器、有线/蓝牙输出及重复启动。

依据：[AVAudioSession](https://developer.apple.com/documentation/avfaudio/avaudiosession)、[Audio route changes](https://developer.apple.com/documentation/avfaudio/responding-to-audio-route-changes)。

**A03 · P1 · 录音状态没有跟随系统中断与生命周期变化（平台生命周期，代码确认）**

应用未注册音频中断、路由变化、媒体服务重置或引擎配置变化处理。录音计时每 50 ms 以墙上时钟更新，状态只由用户按钮和启动异常改变。来电、Siri、输入设备拔除或切到后台导致采集暂停后，界面仍可能保持 `.recording`；回到前台后计时包含未采集区间，当前时间与 Core 样本时间也可能偏离。主 App 的 scenePhase 处理只刷新诊断数据，琴键页的停止逻辑不覆盖录音。

证据：[AnalysisViewModel.swift:262](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/AnalysisViewModel.swift:262)、[LivePitchAudioCapture.swift:80](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Audio/LivePitchAudioCapture.swift:80)、[PitcheeApp.swift:42](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/PitcheeApp.swift:42)。

修复：为录音增加中断/停止状态，监听相关系统通知；明确前台录音的后台行为；安全关闭或重建引擎，提示用户并允许保存有效片段。采用录制样本时长或可暂停的单调计时。用真机测试来电、Siri、锁屏、切后台、耳机切换及媒体服务重置。是否一定发生崩溃尚未验证，本报告不作该断言。

依据：[Handling audio interruptions](https://developer.apple.com/documentation/avfaudio/handling-audio-interruptions)。

**A04 · P1 · 应用内缺少正式隐私政策链接与完整数据说明（Apple 明确要求）**

隐私页只有三项“本机分析、临时录音清理、修改偏好”的承诺，没有可访问的正式隐私政策链接；没有说明历史分析特征、打开日期、本地诊断/对照数据的完整保留及删除政策。仅本地处理的应用也适用 App Review 5.1.1(i) 的隐私政策要求。App Store Connect 上是否已经配置 URL，不在本地代码可核查的范围。

证据：[SettingsView.swift:162](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/SettingsView.swift:162)、[RecordingAssessment.swift:34](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAssessment.swift:34)。

修复：加入明确、易找到的政策链接，政策与实际持久化、权限、本地实验、备份和删除行为保持一致；同步核对 App Store Connect 的隐私标签和政策 URL。本次未替用户编造或发布法律文本。

依据：[App Review Guidelines 5.1.1(i)](https://developer.apple.com/app-store/review/guidelines/#data-collection-and-storage)。

**A05 · P2 · 动态本地化键被当成插值格式，诊断与反馈标签无法正确翻译（已用 SwiftUI 语义探针复现）**

状态：**快照中已复现；交付前工作区源码已修正两处调用**。后续实现先创建 `String` 类型的 `labelKey`，再传入 `LocalizedStringKey`。这项不是本次审查修改的代码；新工作区版本尚未整体重建，也未对两个页面逐项实机验收。

`LocalizedStringKey("settings.localDiagnostics.\(category).\(keys[index]).label")` 的实际存储键是 `settings.localDiagnostics.%@.%@.label`，并非已翻译的具体键。评分反馈中的直接插值同样生成 `scoreStudy.feedback.rating.%lld.label`，目录中没有该键。源码已经提供各具体条目的中文和英文翻译，但这些翻译不会通过当前构造方式被命中；用户会看到内部标识符或格式化后的键名。

证据：[LocalDiagnosticsView.swift:95](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Diagnostics/LocalDiagnosticsView.swift:95)、[LocalScoreStudyView.swift:109](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Diagnostics/LocalScoreStudyView.swift:109)、证据目录 `key-probe.txt`。

修复：先构造明确的 `String` 变量，再传入 `LocalizedStringKey`，或让枚举返回静态的本地化键。为所有直方图条目和五个评分按钮验证实际显示文本，而不只测试计数与评分逻辑。

依据：[LocalizedStringKey](https://developer.apple.com/documentation/swiftui/localizedstringkey)。

**A06 · P2 · 已声明的语言存在大量缺项（本地化完整性，资源核查）**

最终副本目录有 476 个键、29 个语言条目。繁体中文缺少 104 个键；日语、阿拉伯语等 26 个语言各缺少 175 个键，涉及历史、活动、诊断、评分对照和新增无障碍操作。英语的一个缺项是 A05 的错误动态模板，应与普通缺翻译区别处理。许多现有翻译仍标记 `needs_review`，这表示未完成语言审校，不等于翻译必然错误。

证据：[Localizable.xcstrings](/Users/dannyfeng/Documents/Pitchee/Resources/Localizable.xcstrings)、证据目录 `missing-localizations.json`。InfoPlist 的四个键在 29 个语言中都有条目。

修复：为实际发布语言补齐并人工审校；保证不会把语义键作为最终用户文案显示，尤其是诊断和无障碍标签。若暂不支持某个语言，明确调整发布范围。对德语等长文本、阿拉伯语/希伯来语 RTL、复数和辅助字号做实际显示检查。

依据：[Localization](https://developer.apple.com/localization/)、[String catalogs](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)。

**A07 · P2 · 中等高度的说明弹窗没有滚动能力（HIG 无障碍与布局，代码确认）**

建议与资源弹窗使用固定的 `.presentationDetents([.medium])`，内部是含正文和 `Spacer` 的 `VStack`，没有 `ScrollView`。资源弹窗还固定放置 160 pt 图块。辅助字号或较长翻译会把正文推到可视区外，用户不能滚动或扩展到大高度。其他页面已经适配大字，不会自动解决这些独立弹窗。

证据：[RecordingAnalysisView.swift:970](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:970)、[RecordingAnalysisView.swift:1010](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:1010)。

修复：为正文提供滚动区域，允许 `.large`，或在辅助字号直接使用完整高度。验证最大辅助字号、长德语文本与紧凑高度时全文和关闭操作可达。

依据：[HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)、[HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)。

**A08 · P2 · “01:09 视频练习”没有实际视频（产品完整性，代码确认）**

资源卡显示播放图标、视频练习副标题和 `01:09` 时长，但点击后仅打开带装饰图和一段短文字的静态弹窗。没有播放器、媒体资源或播放动作，文章入口也只有简短说明。用户看到的功能承诺与实际行为不一致。

证据：[RecordingAnalysisView.swift:387](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:387)、[RecordingAnalysisView.swift:1010](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:1010)。

修复：提供真实资源与播放/阅读功能，或把入口、图标、副标题和时长改成准确的文字练习说明。不要保留看起来已完成的占位入口。

依据：[App Review 2.1 App Completeness](https://developer.apple.com/app-store/review/guidelines/#app-completeness)。是否构成拒审取决于提交内容与审核判断，本报告确认的是实际功能不匹配。

**A09 · P2 · 长录音缺少资源上限，推理队列没有积压策略（可靠性，风险路径已确认）**

录音没有时长/文件大小限制；实时输入使用默认无界 `AsyncStream`，文件写入队列也可持续积压。完整音高时间轴持续保存在内存，Core 的 `kMaximumSeconds` 为无穷大；WAV 读取先把全文件装入 byte vector，再分配 Float32 数据，后续重采样和模型推理继续产生额外内存。48 kHz 单声道 PCM16 的一小时录音，仅原文件加 Float32 解码数组就约 1.04 GB 十进制内存，尚未计入模型和中间结果。

证据：[LivePitchAudioCapture.swift:62](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Audio/LivePitchAudioCapture.swift:62)、[AnalysisViewModel.swift:282](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/AnalysisViewModel.swift:282)、[wav_reader.cpp:24](/Users/dannyfeng/Documents/Pitchee/Dependencies/PitcheeCore/src/wav_reader.cpp:24)、[internal.hpp:20](/Users/dannyfeng/Documents/Pitchee/Dependencies/PitcheeCore/src/internal.hpp:20)。

修复：按产品用途设录音上限，监控写入失败及积压，在达到上限前安全结束；考虑分块分析和有界管线。由于 Core 要求连续 PCM，不可简单丢弃缓冲区而仍沿用原来的连续时间轴，必须设计过载时的重置/降级/终止行为。压力阈值与实际峰值尚未在最低支持机型测量。

依据：[Reducing your app’s memory use](https://developer.apple.com/documentation/xcode/reducing-your-app-s-memory-use)。

**A10 · P2 · 停止录音会在主线程同步等待全部文件队列（响应性，代码确认）**

`AnalysisViewModel` 在 MainActor 上同步调用 `audioCapture.stop()`，后者通过 `pitchQueue.sync` 排空此前的文件写入与转换任务。遇到存储繁忙、写入积压或长录音时，停止按钮、动画和其他 UI 会一起等待。写入错误当前仅暂存，直到用户按停止才向用户报告。

证据：[AnalysisViewModel.swift:196](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/AnalysisViewModel.swift:196)、[LivePitchAudioCapture.swift:93](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Audio/LivePitchAudioCapture.swift:93)、[LivePitchAudioCapture.swift:127](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Audio/LivePitchAudioCapture.swift:127)。

修复：增加“正在结束录音”状态，将 drain/关闭作为可等待的异步操作完成后再进入分析；首次文件写入失败立即触发安全停止与可恢复错误提示。用慢存储/磁盘空间不足场景验证，避免仅以短录音测试推断没有卡顿。

依据：[Improving app responsiveness](https://developer.apple.com/documentation/xcode/improving-app-responsiveness)。

**A11 · P2 · 历史报告丢失已经显示过的音量数据（数据完整性，代码确认）**

新分析结果包含单独计算的 `RecordingVolumeStatistics`，但 SwiftData 只保存 Core 的结果 payload。进入历史详情与导出时显式传入 `volumeStatistics: nil`；与此同时原 WAV 已删除，无法再计算。这使当次报告有录音电平和音量曲线，稍后从历史打开却只剩空值/空图。这里不是 SwiftData 解码失败，而是模型未持久化这些数据；dBFS 也不能当作经过校准的声压级。

证据：[RecordingAssessment.swift:34](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAssessment.swift:34)、[InsightsDetailViews.swift:215](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:215)、[AnalysisViewModel.swift:315](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/AnalysisViewModel.swift:315)。

修复：为需要长期显示的音量摘要/曲线增加有版本的持久化字段与迁移，旧数据明确标注不可用；若产品有意不保留这些数据，则在当前结果和历史报告中说明并隐藏无法使用的导出选择。无需为了恢复统计而延长原始录音保留。

**A12 · P2 · 主历史数据没有用户可见的删除入口（隐私控制与产品设计）**

本地诊断和评分对照可以清空，但录音分析历史、完整声学特征 payload 和打开日期没有相应删除入口。检索到的 `modelContext.delete` 仅用于保存失败回滚。隐私承诺中的“用户掌控”目前主要指偏好和权限，不能覆盖已存的结果。

证据：[InsightsDetailViews.swift:94](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:94)、[RecordingAssessment.swift:34](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAssessment.swift:34)、[SettingsView.swift:162](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/SettingsView.swift:162)。

修复：提供单条及全部历史删除，说明保留周期与删除范围，并处理正在运行的分析重新写回数据的竞态。此处按本地数据控制缺口评估；应用没有账户，不套用“账户删除”条款。

依据：[App Review 5.1.1 的保留/删除政策要求](https://developer.apple.com/app-store/review/guidelines/#data-collection-and-storage)、[HIG Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy)。

**A13 · P2 · 结果数据图形使用 Liquid Glass，混淆控件与内容层（HIG 设计建议）**

声音特征的比例气泡和音高范围标记属于展示数据，使用了 `.glassEffect`。Apple 当前 Materials 指引明确建议不要把 Liquid Glass 用于内容层；它主要承担导航和控件层级。琴键作为交互控件以及系统 Tab 附件使用玻璃，与这里的静态数据内容用途不同。

证据：[RecordingAnalysisView.swift:1295](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:1295)、[RecordingAnalysisView.swift:1319](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:1319)。

建议：数据图形使用稳定的填充、线条或普通材质，保留准确的面积/数值关系，并检查高对比度和减少透明度下的可读性。这属于明确 HIG 建议，不应被描述成必然拒审。

依据：[HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)。

**需要产品决定或继续改进的事项**

| 项目 | 评估与建议 |
| --- | --- |
| 备份范围 | `PrivateAppStorage` 排除整个 Application Support 和 Preferences，因此无法重建的历史与偏好也被排除，而应用未提供可恢复的备份格式。若出于声音数据隐私而有意保持本机，应明确告知换机/恢复时可能丢失；可考虑用户主动控制的加密导出。Apple 说明 `isExcludedFromBackup` 只是系统提示，不保证数据永不进入备份，不能把它作为绝对隐私承诺。 |
| 原始录音保护 | 本次新增 `.complete` 保护作用于 Library 下的目录；原始 WAV 位于 tmp，未显式设置同样的文件保护等级。应结合录音是否允许锁屏、系统默认保护等级和威胁模型确定策略，并在真机核验文件属性。 |
| 测试体系 | 现有脚本对数学、转换和隐私状态验证较强，但项目没有应用单元测试/UI 测试 Target；无法覆盖音频会话抢占、中断、SwiftData 重启后数据、实际本地化标签与权限错误恢复。优先补这些行为测试，再考虑迁移到 Swift Testing/XCTest。 |
| 架构与可维护性 | ViewModel 同时承担权限、录音、计时、分析、持久化及本地研究编排；报告/说明页面约千行。可以按音频会话协调、录音状态机、历史仓库、报告渲染拆出职责，优先解决 A02/A03/A10，而不是为套用架构名词重写整个应用。 |
| 编码风格 | 格式提示主要是换行/续行缩进、288 处超长行、59 处分号等。建议提交统一的 `.swift-format` 和 CI 规则，避免无关的大面积格式 diff。4 空格、访问修饰符和尾随逗号并非 Apple 发布硬性要求。 |
| Swift 并发 | 当前启用了 MainActor 默认隔离和 approachable concurrency，但仍为 Swift 5 模式。建议逐步开启完整并发检查，重点审查 `@unchecked Sendable` 与回调队列边界；本报告未把未启用 Swift 6 计为缺陷。 |
| C/C++ 加固 | 已启用多项常规警告与脚本沙箱；Enhanced Security、指针认证及额外安全编译器警告未启用。它们是可评估的加固选项，不是 App Store 通用强制项；涉及静态 ONNX 二进制兼容和硬件支持，应独立验证后采用。 |
| PDF 质量 | PDF 先按 scale 1 渲染整页 UIImage 再绘入 PDF，正文是位图，无法作为真正的可选择文字导出，放大时也损失清晰度。最终副本新增文本格式和文本预览，已提供替代访问路径；仍可进一步输出矢量文字及带结构的 PDF。 |
| 性能规模 | 多个页面全量 `@Query` 后在内存过滤/按日分组，完整结果 payload 与摘要同表。大量历史时应评估查询谓词、分页、摘要与大 payload 分离，并使用 Instruments 测量后优化。 |
| 医疗分类 | 工程 `LSApplicationCategoryType` 为 medical；代码内表述更接近练习参考。此键不能证明实际 App Store 分类，需核对提交元数据。若宣称诊断/治疗或健康测量准确度，须另行满足 App Review 1.4.1 的方法和证据要求；本次未评估模型的临床有效性。 |

相关依据：[iCloud Backup 数据管理](https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup)、[Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)、[Swift Testing](https://developer.apple.com/documentation/testing)。Xcode 安全设置检查参考了本机 [audit-xcode-security-settings 技能](/Users/dannyfeng/.codex/skills/audit-xcode-security-settings/SKILL.md) 的设置说明，本次未执行其修改流程。

**建议修复顺序与验收边界**

先解决 A01/A04 的发布信息和 A02/A03 的音频状态问题，再修复 A06、本地历史完整性、错误恢复及弹窗可访问性，随后处理资源上限、设计层级与长期架构。A05 的代码修正需在后续完整构建和界面验证中确认。每一项都以用户行为与构建产物验收，避免仅以“编译成功”关闭问题。

交付前对持续变动的工作区做了有限补查：A05 的两处构造已改正；应用清单缺失、录音 `.record` 与琴键 `.playback` 的会话冲突、隐私政策链接缺失、历史报告传入 `volumeStatistics: nil`、medium-only 弹窗和主线程同步 drain 仍能在当前源码中找到对应证据。本地化检查脚本在新工作区也未通过：当次读取有 565 个应用键和 5 个 InfoPlist 键，后续新增内容还有缺翻译。这些补查不能替代对新版本的完整审查；具体读取时间、文件哈希和缺项数见 [post-snapshot-review.json](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/post-snapshot-review.json)。

本次没有执行 App Store Connect 提交/验证、真机麦克风录制、来电或蓝牙切换、长时间压力与能耗测量、完整 VoiceOver/Switch Control/键盘流程、iOS 17/18 真机或 iPad 多窗口显示检查。当前机器可用的 iOS 27.1 模拟器运行时仅支持 iPhone Duo，不能替代支持设备矩阵。模拟器截图只说明被抽查的状态，不代表全部页面无障碍通过。审核最终结论由 Apple 决定。

证据目录：[Audit-Evidence/2026-09-30](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30)，入口为 [validation-summary.md](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/validation-summary.md)。完整构建日志与两次源码副本位于本次临时目录 `/tmp/pitchee-apple-audit-20260930`；正式报告、关键源码摘录和精选证据保存在项目 Docs 中。
