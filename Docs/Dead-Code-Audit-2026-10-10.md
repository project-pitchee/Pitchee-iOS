# 死代码复核与清理记录

2026-10-10，基于上一轮代码质量修复后的工作区，复核了 App 源码、测试、Preview、脚本、Core 内部实现和 Android 的共享 Core 调用。确认的死代码与残留资源已完成清理，相关测试以及 iOS 模拟器、设备目标构建均通过。

以下审计证据保留清理前的行号与处理建议；实施结果和验证范围见文末。普通重录、实时音高滚动窗口、历史持久化字段及兼容解码类型均保留。

## 有实际运行开销的残留

| 位置 | 证据与处理范围 |
| --- | --- |
| `PitcheeApp/Analysis/AnalysisViewModel.swift:232`，`pitchTimeline` | 生产、测试、Preview 均无调用。其独占的 `recordedPitchSamples` 却仍在第 596 行追加完整音高帧，可清理 getter、第 203 行缓存和第 78/99/328/596/905 行写入。实际界面使用的 `livePitchSamples` 保留。 |
| `Dependencies/PitcheeCore/src/internal.hpp:100`，`PitchResult.voicing` | 仅在 `analyzer.cpp:129` 分配、`:148` 赋值，无任何读取。可去掉这份数组和写入。 |
| `Dependencies/PitcheeCore/src/analyzer.cpp:37`，实时 F0 的 `total_samples` | 仅在第 894 行累加、962 行清零，没有消费者。`spectrum.cpp` 的同名计数器参与帧调度，仍在使用。 |

## 旧练习与 A/B 回放是整个无入口子图

`AnalysisViewModel.swift` 中 `lastPracticeKind:50`、`selectPractice:55`、`endPractice:85`、`saveComparisonFeedback:121` 均没有生产、测试或 Preview 调用。`canConfigurePractice:53` 仅被无调用的 `selectPractice` 使用。

可以进一步证明整条运行时分支不可达：

1. `practice` 是 `private(set)`，第 58 行是唯一非 nil 赋值，来自无调用的 `selectPractice`。当前导航中没有恢复该状态的入口。
2. `takes` 的唯一 append 在第 744–746 行，前提是 `practiceSnapshot != nil`，因此当前生产路径始终为空。
3. 双次录音分支、`removePracticeAudio`、`needsAudioCleanup`、`retainedPracticeURLs`、`previousID`、`retainedForPractice` 和只写不读的 `comparisonFeedback` / `feedbackError` 随之失活。
4. `PracticePlayback.swift:13` 的播放器唯一实例是 ViewModel 第 48 行；启动入口 `toggle(id:url:):22` 没有调用，现有路径只有 `stop()` 空转。清理上述运行时依赖后，可移除播放器及 delegate；`PracticeTake` 也须随整个子图处理。

清理边界：`prepareRetake:63` 仍由普通录音第 316 行调用，必须保留正常重新录音的重置逻辑，只去掉 A/B 分支。历史 SwiftData 字段和解码类型保留，包括 `practicePayload`、`qualityPayload`、`comparedToID`、`comparisonFeedbackRawValue`、`PracticeContext` 等。

## 其他确定的无入口成员

以下均核实了所属类型及调用点，没有把同名重载或协议要求当成引用。

| 文件与行号 | 成员及范围 |
| --- | --- |
| `PitcheeApp/Analysis/AnalysisViewModel.swift:252` | 旧兼容 `errorMessage` / `clearError` 包装无人调用。监听模型的同名成员仍活跃。 |
| `PitcheeApp/Analysis/RecordingTabAccessory.swift:13` | `RecordingTabAccessory` 包装类型无调用，可清理第 13–23 行；同文件 `TabBarAccessory` 和控制条内容仍活跃。 |
| `PitcheeApp/Monitoring/MonitorViewModel.swift:18` | `MonitorKind.subtitleKey` 无读取。`titleKey` 通过动态字符串服务导航标题，仍活跃。 |
| `PitcheeApp/Audio/LivePitchAudioCapture.swift:132` | 同步 `stop()` 兼容接口无调用；UI 使用 `finish()` / `cancel()`。 |
| `PitcheeApp/App/VoicePreferences.swift:51` | `standardMetricTitleText` 无消费者，现有视图使用 `standardMetricTitle`。 |
| `PitcheeApp/App/AppTheme.swift:249` | `color(for: VoicePreference, customHex:)` 无调用，`defaultColor(for:)` 只被它使用；现有主题调用使用另一重载。 |
| `PitcheeApp/App/AppTheme.swift:327` | `Color.appThemeHex` 无读取。反向的 `Color(hex:)` 和旧自定义颜色存储键仍在生产读取。 |
| `PitcheeApp/Practice/VoiceTrainingLibrary.swift:27` | `LibraryTheme.groupedBackground` / `secondaryGroupedBackground` 无读取，可清理第 27–41 行。 |
| `PitcheeApp/Practice/VoiceTrainingLibrary.swift:371` | 两个 `forMatrixKey` 方法组成无根调用链；Matcher 在第 717 行直接按文章 ID 查询。矩阵 JSON 仍参与加载校验，不能一并作为死资源删除。 |
| `PitcheeApp/Practice/VoiceTrainingLibrary.swift:220` | `VoiceTrainingRecommendation.rationale` 只写不读；可连同第 228 行参数、第 236 行赋值、第 706 行实参清理。 |
| `PitcheeApp/Practice/PracticeData.swift:27` | `PracticeKind.metric` 及 `PracticeMetric.unit/value/formatted`（第 66–80 行）无生产或测试消费者。 |
| `PitcheeApp/Insights/InsightsData.swift:116` | `cohorts()` 没有生产、测试、脚本调用。原报告将它和 `dailySummary` 的测试依赖混淆；后者确有测试。 |
| `PitcheeApp/Insights/InsightsDetailViews.swift:156` | `metric` 固定为 `.composite`，第 164 / 192 行的另一条件分支不会执行。 |
| `Dependencies/PitcheeCore/src/ort_runtime.cpp:16` | `ort_available()` 仅有定义及 `ort_runtime.hpp:42` 声明，无 Core、CLI、测试或 Android JNI 调用；不是公开 C API。 |
| `Scripts/build-voice-training-library.py:21` | `STANDALONE_ARTICLES_DIR` 仅赋值；第 50 / 53 行的 `slug` 也从未读取。 |

## 残留文案、权限和生成物

已逐项确认至少 **37 个**旧本地化键没有生产或测试消费者：

| 范围 | 数量 | 定位 |
| --- | ---: | --- |
| `practice.captions.*` | 10 | `Resources/Localizable.xcstrings:61050` |
| `practice.trend.*`（含插值键） | 15 | `Resources/Localizable.xcstrings:82651` |
| `export.pitchImage.preview.a11y/saveChart/saveToFiles/share/share.subject/sheet.title` | 6 | 同 catalog，旧导出按钮/Sheet 文案 |
| `settings.theme.customColor/followVoice/reset` | 3 | `Resources/Localizable.xcstrings:117530` |
| `practice.suggestion.listen.description/subtitle/title` | 3 | `Resources/Localizable.xcstrings:78691`；`.detail` 仍活跃 |

`NSSpeechRecognitionUsageDescription` 也仍残留在项目第 395 / 450 行及 `Resources/InfoPlist.xcstrings:726`。字幕实现已经删除，App 已无 Speech 导入或语音识别请求，可随字幕文案一起清理。

`Scripts/__pycache__/validate-localizations.cpython-314.pyc` 被 Git 跟踪，是可再生的 Python 字节码，不应作为源码维护。

初始文本扫描有更多“没有字面量引用”的键，但没有把它们全部判为死资源：`monitor.<kind>.title`、评分反馈等级、诊断直方图等通过动态键读取；`export.pitchImage.chart.*` 和部分 `recording.timeline.*` 仍服务迁移后的测试夹具。

## 仅测试使用或需要保留

- `PitchTimeline` 在测试中仍有 6 处引用。移除 ViewModel 死 getter 后可以调整归属，不能直接删除文件，因为其中还包含活跃采集需要的类型。
- `AnalysisViewModel.preview` 由控制条与结果页 Preview 的 `.preview(state:)` 隐式调用，`DebugPreviewData.liveSamples` 仍有用途。
- `InsightsData.dailySummary` / `comparable`、历史指标 `.variation`、部分知识库推荐/分类方法仍有语义测试。可以评估是否迁入测试支持，不能只因没有界面入口就丢弃测试。
- `VoiceLibraryMatcher.recommendForPractice` 两个重载、旧推荐分组/`combinedArticles`、`articles(inCategory:)` 仍被知识库测试使用。`PracticeMetric` 的标题等也被运行时本地化测试使用。
- `MonitorAudioCapture.stop()`、采集预算读数、PCM 转换和引擎注入接口仍用于并发/生命周期回归。
- Core 的 spectrum / progress C API 被 Android JNI 和 CLI 使用，`PitcheeCoreAnalyzer.analyze(samples:)` 也有测试调用，不能按 iOS 界面引用删除公开能力。
- `Scripts/fix_terms.py`、`Scripts/normalize_articles.py` 看起来是历史一次性维护脚本，但人工执行也是入口；建议归档审视，暂不列为确定死代码。

## 已完成的清理

- 删除 ViewModel 无消费者的完整音高缓存及 `pitchTimeline` getter；保留界面使用的 30 秒实时滚动窗口。Core 同时移除未读取的 `PitchResult.voicing` 数组、实时 F0 计数器和内部 `ort_available()`；频谱帧调度计数器及公开接口保留。
- 删除无入口的练习选择、双次录音比较、回放及反馈运行时状态，并移除 `PracticePlayback.swift`。普通 `prepareRetake()` 继续重置当前结果；每次录音独立保存历史，分析成功或失败后释放临时 WAV。
- 删除上述已确认的主题、知识库、指标和错误包装等成员，简化 Insights 固定为综合分的分支。知识库矩阵仍在加载时解码并校验；生成脚本清理前后的资源输出一致。
- 共移除 **42 个 Localizable 键**：初次审计的 37 个，加上代码清理后失去引用的 `practice.audio.cleanupError`、`practice.feedback.saveError`、`practice.playback.error`、`monitor.pitch.subtitle` 和 `monitor.spectrum.subtitle`。
- 从两个构建配置及 InfoPlist catalog 移除 `NSSpeechRecognitionUsageDescription`。现有 659 个 Localizable 键、4 个 InfoPlist 键的内容均与清理前一致，29 种语言保留完整。
- 删除受 Git 跟踪的 Python 字节码，补充 `__pycache__/` 和 `*.py[cod]` 忽略规则。

历史练习与质量数据字段、Codable 类型、普通录音的研究入组行为、实际 Preview、测试依赖和 Core / Android 公开能力均未因本轮清理而删除。仅测试使用的接口及用途尚不确定的维护脚本继续保留。工作区已有及并发产生的 HNR、Core、知识库资料与 Xcode 状态改动也已保留，未计入本轮清理成果。

## 验证结果

本轮运行的 **11 个相关测试脚本全部通过**：

| 验证范围 | 结果 |
| --- | --- |
| 录音生命周期 / 音频会话 | 25 + 54 项检查；新增连续三次普通重录、独立历史、滚动窗口及成功 / 失败 WAV 清理覆盖 |
| 实时 F0 / 监听采集 | 212 + 46 项检查，含实际 ONNX / Core 路径 |
| 知识库 | 49 篇文章、17 条规则，加载和推荐测试通过 |
| 评分 / Insights / Dashboard | 310 + 66 + 32 项检查 |
| 练习兼容与迁移 | 37 项检查、SwiftData 迁移及重新打开通过；音频质量 5 项检查 |
| 本地评分研究 | 59 项检查 |
| 本地化 | 663 个键、29 种语言校验，4 项 Python 测试及全部语言运行时测试通过 |
| 音高图片 | 22 项检查 |

原生 Core 本轮 CTest **6 / 6** 通过。iOS 模拟器与设备目标均 `BUILD SUCCEEDED`；两个产物的最低系统版本均为 iOS 17.0，均包含 29 个语言目录，主 Info.plist 和本地化 InfoPlist.strings 均不再包含语音识别权限。App 和 Core 的 `git diff --check` 通过。

构建与测试日志保存在 `.build/dead-code-cleanup-verification/`。设备目标验证为关闭签名的编译验证，未包含真机运行、来电或蓝牙交互测试，也未据此量化性能收益。macOS 测试工具链仍报告现有音频 tap 弃用提示，iOS 构建仅报告未链接 AppIntents 时跳过元数据提取的提示。

修改位于 `codex/dead-code-cleanup` 分支，未提交或推送。
