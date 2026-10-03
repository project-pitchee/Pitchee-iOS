# Pitchee 恢复计划与执行记录：排除首页/结果页破坏性 UI

- **日期**：2026-10-01
- **工作区**：/Users/dannyfeng/Documents/Pitchee
- **目标**：恢复此前已经完成的功能、数据模型、评分、隐私、无障碍、设置和测试改动，同时明确排除某个练习线程对首页和结果页带来的破坏性 UI 入口。
- **关联总记录**：[Pitchee 多线程产品、代码改动与验证总记录](/Users/dannyfeng/Documents/Pitchee/Docs/Pitchee-Conversation-Change-Plan.md)

## 1. 事件描述

之前的多个线程已经完成了大量改动，包括：

- 录音按钮视觉调整。
- 分析失败错误状态修复。
- 男性向声音评分。
- Insights 入口清理。
- About 设置页。
- 本地诊断和隐私保护。
- 本地评分对照。
- 练习数据和趋势模型。
- 无障碍支持。
- 本地化资源。
- 多组自动化测试。

其中一个“引导练习、复测比较、可信趋势”的线程进一步修改了首页和结果页：

- 在首页 Insights/Trends 中加入练习趋势入口。
- 在结果页增加“比较/复练”工具栏按钮。
- 在结果页弹出练习 Hub。
- 在录音页额外增加练习入口。

这些入口改变了既有首页和结果页的信息层级与导航行为，当前产品方向不希望直接引入这组 UI。

随后一次恢复操作误将此前已经完成的其他改动全部丢失，主工作区只剩原始基线和文档。此次恢复的原则是：

> 恢复功能代码和验证材料；保留既有首页、结果页结构；不恢复练习线程新增的首页趋势按钮、结果页比较按钮和结果页练习弹窗。

## 2. 恢复源

主工作区恢复前状态：

- 分支：main。
- 基线提交：f8ed325 Add insights dashboard and analytics。
- 工作区没有功能代码改动。
- 只有 Xcode 用户界面状态文件发生变化。
- 没有可用 stash。
- Git 没有可直接 cherry-pick 的正常提交。

在 Codex 管理的工作树中找到了保留的未提交改动：

| 工作树 | 用途 |
|---|---|
| /Users/dannyfeng/.codex/worktrees/483b/Pitchee | 综合恢复源，包含练习、诊断、隐私、无障碍、本地化和大量测试 |
| /Users/dannyfeng/.codex/worktrees/8053/Pitchee | 男性向评分、趋势、结果和导出展示 |
| /Users/dannyfeng/.codex/worktrees/6cff/Pitchee | About/Preferences 标准设置页 |

恢复前检查：

~~~sh
git status --short
git diff --stat
git log --oneline --decorate -20 --all
git branch -a
git stash list
git worktree list --porcelain
git fsck --no-reflogs --unreachable
~~~

发现的唯一不可达提交是旧的 Insights 基线版本：

d3f04ce3e4ef926ea802dc65bfbc5164846fbb82

它与当前 f8ed325 使用同一个父提交，代码基本相同，不能恢复后续线程的未提交改动。因此实际恢复使用了仍然存在的 Codex 工作树文件。

## 3. 恢复边界

### 3.1 恢复的功能改动

以下内容已经从恢复源带回：

- AnalysisViewModel 的录音/分析错误分离。
- 练习上下文、A/B Take 和质量快照。
- 录音质量分析和削波检测。
- SwiftData 历史元数据扩展。
- 男性向评分核心和方向分数。
- 历史、趋势和导出目标方向同步。
- 本地诊断和本地评分实验。
- 备份排除和私有存储保护。
- 本地字幕。
- 实时图表无障碍时间线。
- PDF 文本报告和无障碍操作。
- About 标准设置页。
- 29 种语言资源和验证工具。
- 研究协议、预算计算和合成模拟。
- 相关测试、脚本和文档。

### 3.2 明确排除的 UI 改动

以下内容没有恢复：

- 首页 Trends/Insights 中的 PracticeTrendsView 导航按钮。
- 结果页左上角的 practice.compare 工具栏按钮。
- 结果页打开 PracticeHubView 的 Sheet。
- 录音页额外的 PracticeHubView 工具栏入口。
- 练习线程为了引导流程而新增的首页卡片或结果页操作入口。

练习相关的数据模型和实验代码仍然保留，但练习 UI 不会自动插入首页或结果页。今后如果需要入口，应单独设计并重新确认信息层级和导航位置。

### 3.3 保留的结果页功能

结果页中以下变化属于男性向评分功能，而非被排除的练习 UI，因此保留：

- 根据当前声音偏好显示方向分数。
- 显示男性向标准分和自然度分。
- 结果页评分说明使用对应方向。
- 历史和导出沿用同一个方向评分。
- 本地评分实验显示前的结构化自评流程。

## 4. 具体文件恢复

### 4.1 综合恢复源带回的文件

从 483b 带回：

- AnalysisViewModel.swift
- AudioSessionController.swift
- InsightsData.swift
- LivePitchAudioCapture.swift
- PianoSoundEngine.swift
- PitchImageExportButton.swift
- PitchTimeline.swift
- PitcheeApp.swift
- RecordingAssessment.swift
- RecordingStatistics.swift
- VoicePreferences.swift
- AudioSessionCoordinator.swift
- AccessibilitySupport.swift
- LocalDiagnostics.swift
- LocalDiagnosticsStore.swift
- LocalDiagnosticsView.swift
- LocalScoreStudy.swift
- LocalScoreStudyStore.swift
- LocalScoreStudyView.swift
- PracticeCaptions.swift
- PracticeData.swift
- PracticeHubView.swift
- PracticePlayback.swift
- PracticeTrendsView.swift
- PracticeViews.swift
- PrivateAppStorage.swift
- ScoreStudyEvaluator.swift
- VoiceScoring.swift

同时带回：

- InfoPlist.xcstrings
- Localizable.xcstrings
- PrivacyInfo.xcprivacy
- project.pbxproj
- 本地诊断、评分实验、练习、研究协议和本地化验证脚本。
- 对应 Swift、C++、Python 测试。
- 相关产品、隐私、研究和无障碍文档。

### 4.2 首页 ContentView.swift

首页没有直接复制综合恢复源，而是用男性评分版本作为基础后手动重组。

保留：

- 首页趋势使用当前目标方向重新计算分数。
- 每日最佳和平均值使用目标方向。
- About Tab 进入 SettingsView。
- Trends 顶部不再显示旧的设置按钮。
- recordingAction 使用 needsAnalysisScreen，支持本地评分反馈等待状态。
- Insights 不再从页面内部触发录音。
- 空状态只显示时间范围内没有分析记录的说明。

排除：

- PracticeTrendsView 首页导航按钮。
- 练习专用首页入口。
- 首页“开始练习”卡片。

### 4.3 结果页 RecordingAnalysisView.swift

结果页使用男性向评分版本作为基础，并加入本地评分反馈状态。

保留：

- ScoreStudyFeedbackView。
- 分析前结构化自评。
- 分析状态和反馈状态的导航保护。
- 男性向结果分数、方向标准分、说明公式和导出使用目标方向。

排除：

- showsPractice 状态。
- practice.compare 工具栏按钮。
- PracticeHubView Sheet。
- 结果页直接开始复练的 UI 入口。

### 4.4 录音页 RecordingView.swift

录音页没有恢复练习线程增加的练习工具栏和 Sheet。

恢复：

- 录音错误只使用 recordingError。
- 分析错误不会触发录音页弹窗。
- 点击确认后只清除录音错误。
- 保留原来的查看最近分析按钮。

排除：

- 录音页新增的 practice.screen.title 工具栏入口。
- 录音页打开 PracticeHubView 的 Sheet。

### 4.5 RecordingTabAccessory.swift

综合工作树中的按钮样式与用户要求不一致，因此没有直接复制。当前恢复后的按钮按最初视觉需求手动调整：

- 保留 Tab Bar 上方原生组件。
- 空闲显示 record.circle。
- 录音显示 stop.circle。
- 分析等待显示 arrow.up.right.circle。
- 使用红色单色图标。
- 删除蓝色实心背景和 borderedProminent。
- 44pt 触控区域。
- 支持 Reduce Motion。
- 支持动态字号和 VoiceOver 标签。

### 4.6 SettingsView.swift

使用 6cff 的标准设置页版本，再补回本地工具入口：

保留：

- About 标准分组列表。
- 声音偏好当前值。
- 声音偏好子页和勾选状态。
- 隐私详情页。
- 实际应用版本号。
- 本地诊断入口。
- 本地评分对照入口。
- 练习音频生命周期说明。

## 5. Insights 入口清理

InsightsDetailViews.swift 和 ContentView.swift 中已经移除：

- InsightsPage 顶部右侧录音按钮。
- 录音历史页空状态录音按钮。
- 指标详情页空状态录音按钮。
- 活跃日历页右侧录音按钮。
- onRecordTapped 回调参数。
- 旧的录音导航调用。

保留：

- Tab Bar 作为唯一录音入口。
- 历史、活动、指标详情和空状态的说明文字。
- 指标详情中的评分方向展示。
- 历史记录和导出入口。

检查方式：

~~~sh
rg -n "onRecordTapped|insights.record.action|mic.badge.plus|PracticeTrendsView|practice.compare|PracticeHubView" \
  PitcheeApp/App/ContentView.swift \
  PitcheeApp/Insights/InsightsDetailViews.swift \
  PitcheeApp/Analysis/RecordingAnalysisView.swift \
  PitcheeApp/Analysis/RecordingView.swift
~~~

结果：

- 首页/结果页目标 UI 标记没有引用。
- Insights 旧录音回调没有引用。
- PracticeHubView 文件存在，但没有被首页、结果页或录音页自动打开。

## 6. 恢复操作记录

实际使用的综合复制操作：

~~~sh
rsync -a \
  --exclude='.git' \
  --exclude='Pitchee.xcodeproj/project.xcworkspace/xcuserdata' \
  --exclude='PitcheeApp/App/ContentView.swift' \
  --exclude='PitcheeApp/Analysis/RecordingView.swift' \
  --exclude='PitcheeApp/Analysis/RecordingAnalysisView.swift' \
  --exclude='PitcheeApp/Analysis/RecordingTabAccessory.swift' \
  --exclude='PitcheeApp/App/SettingsView.swift' \
  --exclude='PitcheeApp/Insights/InsightsDetailViews.swift' \
  /Users/dannyfeng/.codex/worktrees/483b/Pitchee/ \
  /Users/dannyfeng/Documents/Pitchee/
~~~

之后分别复制：

~~~sh
cp /Users/dannyfeng/.codex/worktrees/8053/Pitchee/PitcheeApp/App/ContentView.swift \
  /Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift

cp /Users/dannyfeng/.codex/worktrees/8053/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift \
  /Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift

cp /Users/dannyfeng/.codex/worktrees/8053/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift \
  /Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift

cp /Users/dannyfeng/.codex/worktrees/6cff/Pitchee/PitcheeApp/App/SettingsView.swift \
  /Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/SettingsView.swift
~~~

然后手动应用以下补丁：

1. 首页改用 SettingsView。
2. 首页录音动作改用 needsAnalysisScreen。
3. 删除首页练习趋势导航。
4. 删除首页旧的设置按钮。
5. 删除 Insights 页面录音回调和空状态录音按钮。
6. 结果页加入评分反馈状态。
7. 删除结果页练习比较按钮和 Sheet。
8. 录音页弹窗只观察 recordingError。
9. 录音栏改为 record.circle/stop.circle/arrow.up.right.circle。
10. 设置页补回本地诊断和本地评分实验入口。
11. 删除 InsightsDetailViews.swift 中重复的 InsightsMetric.tint 扩展，解决恢复源之间的重复声明。

## 7. 验证操作

### 7.1 静态检查

~~~sh
git diff --check
~~~

结果：通过。

### 7.2 首页和结果页破坏性 UI 引用检查

~~~sh
rg -n "PracticeTrendsView|PracticeHubView|practice.compare|onRecordTapped|AboutView|settingsLink" \
  PitcheeApp/App/ContentView.swift \
  PitcheeApp/Analysis/RecordingAnalysisView.swift \
  PitcheeApp/Analysis/RecordingView.swift \
  PitcheeApp/Insights/InsightsDetailViews.swift
~~~

结果：

- 没有首页练习趋势入口。
- 没有结果页练习比较按钮。
- 没有结果页练习 Sheet。
- 没有录音页练习工具栏入口。
- 没有旧的 Insights 录音回调。
- 没有旧的 AboutView 引用。

### 7.3 iOS Simulator 构建

~~~sh
xcodebuild \
  -project Pitchee.xcodeproj \
  -scheme Pitchee \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/pitchee-recovery-build \
  CODE_SIGNING_ALLOWED=NO \
  build
~~~

结果：

~~~text
BUILD SUCCEEDED
~~~

唯一警告：

- App Intents 元数据处理器提示项目没有 AppIntents.framework 依赖，跳过元数据提取。
- 该警告不影响构建。

### 7.4 功能和数据测试

~~~sh
Scripts/test-practice.sh
Scripts/test-insights.sh
Scripts/test-local-diagnostics.sh
Scripts/test-local-score-study.sh
Scripts/test-voice-scoring.sh
Scripts/test-research-protocol.sh
Scripts/test-pitch-image.sh
~~~

结果：

| 检查 | 结果 |
|---|---:|
| Practice | 29 项通过 |
| Practice migration | 原有字段保持不变，新元数据保持未知 |
| Insights | 53 项通过 |
| Local diagnostics | 45 项通过 |
| Local score study | 59 项通过 |
| Voice scoring | 10,742 项通过，覆盖 1,530 个 Core 参考案例 |
| Research protocol | 20 项通过 |
| Pitch image/export | 22 项通过 |
| Recording quality audio | 5 项通过 |

## 8. 目前恢复后的行为边界

### 应该存在

- 男性向评分和方向说明。
- 目标方向下的历史、趋势和导出。
- About 中的声音偏好、隐私、本地诊断和评分实验。
- 本地诊断默认关闭。
- 评分对照实验默认关闭。
- 练习数据模型和本地质量判断。
- A/B 音频生命周期处理。
- 无障碍图表和本机字幕代码。
- 本地化资源和测试脚本。
- Tab Bar 上方的原生录制栏和简洁录音图标。
- Insights 内部没有重复录音入口。

### 不应该自动出现

- 首页练习趋势卡片或按钮。
- 结果页“比较”按钮。
- 结果页练习 Sheet。
- 录音页新的练习工具栏按钮。
- 首页因练习模块改变原有卡片顺序。
- 结果页因练习模块改变原有评分信息层级。
- 录音入口重新散落在 Insights 子页面。

## 9. 尚未完成的验证

恢复逻辑和自动测试已经通过，但以下项目仍需真机或可用模拟器完成：

- 首页和结果页最终截图对照原始基线。
- Recording 原生栏在浅色、深色和动态字号下的视觉确认。
- 男性向公式页面两条公式占位问题的最终视觉复验。
- 分析失败后返回并重新录音的真实交互。
- A/B 练习的真实朗读和回听。
- 麦克风权限、耳机切换、来电中断、锁屏和前后台。
- VoiceOver、Switch Control、Assistive Access 和 Screen Curtain。
- Android 构建、备份和恢复。
- 29 种语言的最终语言审校。

## 10. 后续操作原则

1. 不直接把任何练习线程的整棵工作树覆盖到主工作区。
2. 涉及 ContentView.swift、RecordingAnalysisView.swift 和 RecordingView.swift 时，必须逐 hunk 复核。
3. 练习数据和评分逻辑可以独立恢复，不代表要同时恢复练习入口 UI。
4. 首页和结果页的 UI 变化必须单独列为产品决策。
5. 在用户明确确认前，不新增首页练习卡片或结果页练习按钮。
6. 运行静态引用检查，确认以下字符串没有出现在首页/结果页入口中：
   - PracticeTrendsView
   - practice.compare
   - PracticeHubView
7. 在真机验收前，不把 Simulator 构建通过描述为完整 UI 验收。
8. 不把本地诊断或评分实验改成默认上传。
9. 以后再次恢复时，优先使用文件级或 hunk 级恢复，而不是整树覆盖。

## 11. 当前结论

本次恢复已经完成代码层面的选择性合并：

- 应恢复的功能和测试已带回。
- 首页和结果页的练习入口没有带回。
- 男性向评分在结果页的必要显示保留。
- Insights 内部重复录音入口已清理。
- iOS Simulator 构建通过。
- 所有恢复源中已有的核心自动测试通过。

当前工作区仍有大量未提交改动，下一步应先进行一次人工代码审阅和真机 UI 验收，再决定是否拆分提交。

