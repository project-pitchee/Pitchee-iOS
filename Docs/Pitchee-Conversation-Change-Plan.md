# Pitchee 多线程产品、代码改动与验证总记录

- **整理日期**：2026-10-01
- **工作区**：`/Users/dannyfeng/Documents/Pitchee`
- **关联工作区**：`/Users/dannyfeng/Documents/Pitchee-Android`
- **整理依据**：本次用户消息中引用的 10 个 Codex 线程，均已通过 `read_thread` 读取后整理。
- **记录目的**：保留讨论中已经确认的需求、实际代码改动、验证操作、验证结果、未完成事项和后续计划，作为后续合并、验收和排期的基线。

## 0. 阅读范围和状态解释

本次核对的线程如下：

| 序号 | 线程 ID | 主题 | 线程中可确认的状态 |
|---:|---|---|---|
| 1 | `01a0f224-0c62-7850-8b0a-867c9d8f32bd` | Recording 原生录制栏右侧按钮视觉调整 | 代码和构建完成；视觉复验受模拟器阻断 |
| 2 | `01a0f221-34ff-7790-8bf4-98bec050d78f` | 分析失败后返回出现反直觉弹窗 | 代码修复和构建完成；真实交互尚未完成 |
| 3 | `01a0f231-de1d-7390-bea2-e7b2ed6e4ec6` | App 下一步建议 | 产品建议完成；后续练习实现已在其他线程继续 |
| 4 | `01a0f200-e496-7760-84d1-0682ee165fa6` | 显示男性向声音评分 | 评分实现、历史和导出大部分完成；公式页面仍有最终视觉复验问题 |
| 5 | `01a0f227-e5c1-7220-b5d4-2824912ea20e` | Insights 中重复的录音入口 | 代码、文案和导航调用已移除；模拟器点击验证受阻 |
| 6 | `01a0f214-34a0-7722-a2e3-adda5b90406e` | Preferences & Privacy 移到 About | 页面迁移和设置页改造完成；部分最终视觉复验受阻 |
| 7 | `01a0f206-a659-7f22-9052-593ece48407d` | 不上传音频的模型改进数据方案 | 本地诊断、评分对照和离线研究协议完成；线上采集未实现 |
| 8 | `01a0f22d-a9ed-7dd2-9c30-1060932a7040` | 本地化标题大小写和缺译验证 | 英文大小写修复完成；全量译文合并和语言审校仍在进行 |
| 9 | `01a0f22b-6c96-71e2-85cd-6c666cc5afad` | 读取目标文件并完成 P0–P2 无障碍改进 | 多项无障碍实现和检查清单完成；真机和辅助技术实测未完成 |
| 10 | `01a0f235-6cd4-7d60-8210-726c51a2c070` | “引导练习、复测比较、可信趋势”实现 | 练习闭环大部分实现；真实设备流程和部分视觉验收待完成 |

部分线程由于用量限制、模拟器安装超时、Device Hub/ScreenCaptureKit 错误或工作区并行改动而显示为 `failed` 或 `interrupted`。本文件只把线程中明确出现的文件改动、验证结果和代理最终陈述记录为已确认内容，不把失败线程自动视为完全交付。

## 1. 整体产品方向

这些对话逐渐形成了一条连续的产品路线：

1. 先修正录音页面和分析失败流程，减少明显的 UI 和状态错误。
2. 统一评分方向，补齐男性向声音评分的计算、说明、历史和导出。
3. 清理 Insights 中重复的录音入口，让 Tab Bar 成为唯一录音入口。
4. 把 Preferences & Privacy 整合进标准化的 About 设置页。
5. 把“看完分数”发展为“选择目标—固定语料练习—分析—复练—比较”。
6. 把趋势从“每天最高分”改为同类练习的中位数、范围和有效次数。
7. 在不上传音频的前提下，建立本地诊断和本地评分对照实验。
8. 为未来的群体研究准备安全聚合、差分隐私和固定发布协议，但当前不接入上传。
9. 补齐 P0–P2 无障碍能力。
10. 统一英文标题式大小写，并继续补齐 29 种语言的新功能文案。

当前的核心产品判断是：**下一步最有价值的功能不是继续增加单个分数，而是让用户完成一次有明确目标、可重复、可回听、可比较的练习。**

## 2. Recording 原生录制栏按钮

### 2.1 原始需求

用户认为：

- Tab Bar 上方的原生录制组件设计很好，应当保留。
- 右侧的麦克风按钮视觉上很丑。
- 需要改善按钮样式，但不改变录音栏的位置和整体交互。

### 2.2 已确认的代码修改

文件：

- [`PitcheeApp/Analysis/RecordingTabAccessory.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingTabAccessory.swift)

具体修改：

- 删除蓝色实心圆底和白色麦克风组合。
- 使用系统 SF Symbol：
  - 空闲状态：`record.circle`
  - 录音状态：`stop.circle`
  - 分析等待状态：`arrow.up.right.circle`
- 使用单色渲染：
  - 分析前/空闲使用主色。
  - 录音状态使用红色。
- 图标字号约为 32pt。
- 保留 44×44pt 点击区域。
- 使用 `.buttonStyle(.plain)`，避免系统按钮样式再次生成突兀底盘。
- 使用 `.symbolRenderingMode(.monochrome)`。
- 使用 `.contentTransition(.symbolEffect(.replace))`，并在 Reduce Motion 时退化为无动画。
- 保留轻量触觉反馈。
- 增加 VoiceOver：
  - `accessibilityLabel`
  - `accessibilityHint`
  - `accessibilityIdentifier("recording.primaryAction")`
  - `accessibilityInputLabels`
- 录音栏文字支持动态字体；辅助功能字号下隐藏次要副标题，避免右侧按钮被挤压。

### 2.3 验证操作和结果

已执行或记录的操作：

- iOS Simulator Debug 构建。
- `git diff --check`。
- 尝试启动独立预览工程，分别检查浅色、深色和不同状态。
- 生成过录制栏截图验证文件。

结果：

- 构建通过。
- 本地化资源成功编译。
- 代码差异检查通过。
- 模拟器安装长期卡住，Device Hub 和 ScreenCaptureKit 捕获出现异常。
- 因此不能把最终截图视为成功的视觉验收。

### 2.4 未完成事项

- 在真实 iPhone 上确认原生栏高度、图标比例和横向对齐。
- 在浅色、深色、最大动态字体下确认按钮不会与文字重叠。
- 确认录音、停止、分析等待三个状态的转场动画在 Reduce Motion 下符合预期。

## 3. 分析失败后返回时出现错误弹窗

### 3.1 原始问题

分析失败后返回录音页，录音页会弹出一个看起来像“录音启动失败”的错误提示。该提示与用户刚刚经历的分析失败不匹配，属于反直觉反馈。

根因：

- 录音页和分析页共用一个错误状态。
- 页面返回时分析错误尚未清理。
- 录音页把分析错误误当成录音错误。
- 错误清理依赖页面离开时机，存在时序问题。

### 3.2 已确认的代码修改

文件：

- [`PitcheeApp/Analysis/AnalysisViewModel.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/AnalysisViewModel.swift)
- [`PitcheeApp/Analysis/RecordingView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingView.swift)
- [`PitcheeApp/Analysis/RecordingAnalysisView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift)

具体修改：

- 将录音相关错误和分析相关错误拆分为独立状态。
- `RecordingView` 的弹窗只观察录音权限、录音启动和录音保存错误。
- `RecordingAnalysisView` 保留分析失败说明。
- 分析页面不再依赖离开页面时机清除错误。
- 开始新的录音时重置旧的录音和分析错误。
- 保留真正需要弹窗的场景：
  - 麦克风权限拒绝。
  - 录音启动失败。
  - 音频文件保存失败。
  - 必要的录音资源错误。

### 3.3 验证操作和结果

已完成：

- Swift 语法和差异检查。
- iOS Simulator Debug 构建。
- 代码路径复查，确认返回时录音页不再读取分析错误。

尚未完成：

- 真实录音产生分析失败。
- 点击返回录音页。
- 确认不再弹出错误。
- 再次录音并确认旧状态已被清理。
- 模拟器设备安装和交互验证被服务异常阻断。

## 4. App 下一步产品建议

### 4.1 建议的产品主线

建议 Pitchee 围绕三个词推进：

- **引导练习**
- **复测比较**
- **可信趋势**

当前已有实时音高、录音分析、历史趋势和本地评分实验，但用户看完结果后仍缺少明确的下一步。产品应该把结果页变成练习入口。

### 4.2 第一阶段建议

第一阶段应包括：

1. 首页显示“开始一次练习”。
2. 如果存在未完成练习，显示“继续上次练习”。
3. 让用户选择本次关注点：
   - 音高观察。
   - 音高稳定性。
   - 日常朗读。
4. 为每次练习提供固定短句。
5. 一次只突出一个主要反馈。
6. 录音后展示质量是否适合比较。
7. 点击“用同一句再试一次”。
8. 对比两次结果和回放。
9. 允许用户记录主观听感。

### 4.3 趋势口径建议

原有逻辑是每天选综合分最高的一条，并从这条记录取音高和自然度。这更像“今日最佳”，不适合作为默认进步趋势。

建议改为：

- 同类练习每日中位数。
- 同日范围。
- 有效次数。
- 质量合格次数。
- “最佳表现”单独展示。
- 只比较同一练习目标、同一固定文本和同一模型版本。
- 保存当次目标和评分规则版本。
- 区分“当时记录的分数”和“按当前目标重新查看的分数”。

### 4.4 录音质量建议

质量信息应先于分数出现：

- 有效语音不足。
- 声音偏小。
- 背景噪声较强。
- 削波比例过高。
- 处理时间异常。

质量不足的记录可以保留，但默认不进入个人基线或趋势。提示应给出操作建议，例如：

> 保持相同距离，重新读完整段文字。

不能仅凭自然度分数低就断言存在明确的发声问题。自然度阈值更适合作为待验证的提示条件。

### 4.5 iOS 回听建议

Android 已有音频保存和回放基础；iOS 原本在分析结束时删除临时音频，因此需要调整生命周期：

- 只保留当前练习的 A/B 两段录音。
- 练习结束后清理。
- 异常退出后下次启动清理。
- 长期收藏需要用户主动选择。
- 页面明确说明临时音频保留时间。

### 4.6 目标方向建议

“暂不确定”不应默认使用某一个方向的评分。建议：

- 默认展示音高、波动和个人变化。
- 用户主动选择后才显示男性向或女性向方向评分。
- 后续可支持：
  - 维持当前声音。
  - 探索舒适音域。
  - 向更高或更低方向练习。

## 5. 男性向声音评分

### 5.1 原始需求

用户希望继续完成男性向声音评分，并确认：

- 评分数值。
- 公式说明。
- 历史趋势。
- 每日最佳。
- 导出报告。
- 目标切换后的统一表现。

### 5.2 已确认的评分规则修改

文件：

- [`PitcheeApp/Analysis/VoiceScoring.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/VoiceScoring.swift)
- [`PitcheeApp/App/VoicePreferences.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/VoicePreferences.swift)
- [`PitcheeApp/Analysis/RecordingAnalysisView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift)
- [`PitcheeApp/Insights/InsightsDetailViews.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift)
- [`PitcheeApp/Analysis/RecordingExportView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift)
- [`PitcheeApp/App/SettingsView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/SettingsView.swift)

核心规则：

- 男性化倾向使用：
  `100 - 女性化倾向分`。
- 音高贡献按低音方向计算。
- 保留自然度权重。
- 男性向加分和封顶规则与女性向规则保持对称。
- 缺少有效音高时使用明确的不可用处理，不伪造音高贡献。
- 兼容旧版保存的声音偏好值。
- 结果页、历史、趋势和导出使用同一个目标方向和评分实现。
- 目标切换重新计算展示分数，但不修改原始分析结果。
- 补齐七类规则的说明：
  - 触发条件。
  - 公式。
  - 加分。
  - 封顶。
  - 缺失音高时的行为。
  - 自然度权重。
  - 最终综合分处理。

### 5.3 UI 验证数据

隔离测试数据包含：

- 低音记录。
- 高音记录。
- 缺失音高记录。
- 同一天的多条记录。

已核对的示例：

- 同一条 120 Hz 录音：
  - 男性向显示 100 分、倾向分 80。
  - 女性向显示 32 分、标准分 20。
- 男性向趋势页：
  - 每日最佳切换到 120 Hz 记录。
  - 当前分数显示 100。
  - 平均基准显示 60。
  - 提升显示 67%。
- 女性向趋势页：
  - 每日最佳切换到 200 Hz 记录。
  - 平均基准显示 50。
  - 提升显示 101%。

### 5.4 验证结果

通过：

- 1,530 组 C++ 核心参考数据。
- 53 项历史与趋势检查。
- iOS Simulator 构建。
- 结果页分数和目标标签。
- 趋势页每日最佳和平均值。
- 两页导出报告的分数、分页和目标标签。
- 公式中的平均音高符号修正。
- 长的自然度公式拆行。
- 导出页面无明显重叠或截断。

待完成：

- “当前规则”页面有两条公式曾持续显示加载占位。
- 需要完成公式渲染修复后的最终截图和真机确认。
- 尚未完成真机录音实测。

### 5.5 测试文件

- [`Scripts/test-voice-scoring.sh`](/Users/dannyfeng/Documents/Pitchee/Scripts/test-voice-scoring.sh)
- [`Tests/Voice/VoiceScoringReference.cpp`](/Users/dannyfeng/Documents/Pitchee/Tests/Voice/VoiceScoringReference.cpp)
- [`Tests/Voice/VoiceScoringTests.swift`](/Users/dannyfeng/Documents/Pitchee/Tests/Voice/VoiceScoringTests.swift)
- [`Tests/Insights/InsightsDataTests.swift`](/Users/dannyfeng/Documents/Pitchee/Tests/Insights/InsightsDataTests.swift)
- [`Docs/Native-Core-Integration.md`](/Users/dannyfeng/Documents/Pitchee/Docs/Native-Core-Integration.md)

## 6. Insights 录音入口移除

### 6.1 原始需求

用户认为指标详情页右上角的“开始新的录制”是无意义干扰，因为用户随时可以从 Tab Bar 进入 Recording。

### 6.2 已确认的代码修改

文件：

- [`PitcheeApp/App/ContentView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift)
- [`PitcheeApp/Insights/InsightsDetailViews.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift)
- [`Docs/Localization-Key-Mapping.md`](/Users/dannyfeng/Documents/Pitchee/Docs/Localization-Key-Mapping.md)

已移除：

- 指标详情页右上角按钮。
- 录音历史页按钮。
- 活跃日历页按钮。
- Insights 首页空状态按钮。
- 历史页空状态按钮。
- 指标详情页空状态按钮。
- 所有对应的录音回调和旧导航参数。
- 两条已经没有引用的本地化按钮文案。
- 无障碍导航和普通导航中传递旧录音回调的调用。

空状态现在只保留：

- 当前没有可显示数据的说明。
- 时间范围提示。
- 统一从 Tab Bar 进入 Recording。

### 6.3 验证

已通过：

- Swift 语法检查。
- `git diff --check`。
- 本地化资源检查。
- 多次 iOS Simulator 构建。

未完成：

- 模拟器点击验证。
- 最后一轮整包构建曾受到并行练习模块缺少类型定义的影响；之后 Insights 自身的引用和语法已清理。

## 7. About 设置页改造

### 7.1 原始需求和用户决策

原始需求：

> 把 Preferences & Privacy 的页面移动到 About，将 About 设计成为标准的设置页面。

后续用户明确决定：

- 保留声音选项目前的原生点击反馈。
- 继续完善现有设置页，不增加新的设置功能。

### 7.2 已确认的代码修改

文件：

- [`PitcheeApp/App/SettingsView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/SettingsView.swift)
- [`PitcheeApp/Diagnostics/LocalDiagnosticsView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Diagnostics/LocalDiagnosticsView.swift)
- [`PitcheeApp/App/ContentView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift)
- [`PitcheeApp/App/PitcheeApp.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/PitcheeApp.swift)
- [`Resources/Localizable.xcstrings`](/Users/dannyfeng/Documents/Pitchee/Resources/Localizable.xcstrings)

已完成：

- About 使用标准分组设置列表。
- About 包含：
  - 声音偏好。
  - 隐私说明。
  - 本地改进诊断。
  - 应用信息。
- 声音偏好行显示当前值。
- 声音偏好页显示勾选状态并自动保存。
- 隐私说明独立为详情页。
- 版本号读取应用真实版本。
- 移除 Trends 原来的 Preferences & Privacy 入口。
- 保持声音选项原生按钮和点击反馈。
- 大字号下缩小装饰图标占位。
- 调整标题、图标和摘要的对齐。
- 把本地诊断说明放到对应分组的脚注。
- 为 VoiceOver 增加入口标签、当前值和更完整的朗读结构。
- 隐私说明合并成适合一次朗读的逻辑单元。
- 隐私页支持大字体换行和较长段落。

### 7.3 验证

通过：

- 完整 iOS Simulator 构建。
- 中文、英文、大字体和部分深色模式预览。
- 本地诊断入口文案覆盖检查。
- 29 种语言的诊断入口标题检查。

待完成：

- 英文大字体长隐私文案。
- 阿拉伯语 RTL。
- 中文深色模式。
- 最终安装后的截图复验。

模拟器多次出现：

- 启动超时。
- 安装卡住。
- 启动完成后回到关机状态。
- Device Hub 捕获异常。

## 8. 不上传音频的本地改进数据方案

### 8.1 设计原则

目标是：

- 不上传音频。
- 不上传声纹。
- 不上传逐次录音记录。
- 仍然获得足以指导模型改进的统计资料。
- 把“本地可以统计”和“未来可以安全发布的群体结果”分开。

### 8.2 本地诊断原型

主要文件：

- [`PitcheeApp/Diagnostics/LocalDiagnostics.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Diagnostics/LocalDiagnostics.swift)
- [`PitcheeApp/Diagnostics/LocalDiagnosticsStore.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Diagnostics/LocalDiagnosticsStore.swift)
- [`PitcheeApp/Diagnostics/LocalDiagnosticsView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Diagnostics/LocalDiagnosticsView.swift)
- [`PitcheeApp/App/PrivateAppStorage.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/PrivateAppStorage.swift)
- [`Tests/Diagnostics/LocalDiagnosticsTests.swift`](/Users/dannyfeng/Documents/Pitchee/Tests/Diagnostics/LocalDiagnosticsTests.swift)
- [`Scripts/test-local-diagnostics.sh`](/Users/dannyfeng/Documents/Pitchee/Scripts/test-local-diagnostics.sh)

保存内容限制为固定类别和区间：

- App 版本、构建号、模型清单哈希和测量版本。
- 分析成功、失败、取消、中断和无语音类别。
- 录音长度区间。
- 有效语音比例区间。
- 电平类别。
- 处理耗时区间。
- 背景参考是否可用。
- 质量判断类别。

明确不保存：

- 音频。
- 声音特征。
- 精确分数。
- F0 时间轴。
- 声纹。
- 转写。
- 单次录音标识。
- 用户身份。

保存限制：

- 默认关闭。
- 每个 7 天周期最多记录前 5 次分析。
- 正常使用不受该上限影响。
- 过期汇总在下次启动或回到前台时清理。
- 关闭或清空后，迟到的异步分析结果不能重新写入。
- 清空不会重置已经消耗的额度。
- 应用重启前未完成的分析记为“中断”，保留失败分母。

质量检查中确认的边界包括：

- 有效语音至少 5 秒才允许进入比较。
- 电平边界使用约 -45 dBFS。
- 背景参考不足时不虚构背景噪声。
- 背景阈值边界约为 -35 dBFS。
- 削波比例达到 1% 时不能进入比较。
- NaN、无穷大和缺失必要指标不能通过质量检查。

### 8.3 存储保护

iOS：

- 历史、偏好和诊断目录设置备份排除。
- 关闭 SwiftData CloudKit。
- 临时录音在结束或异常恢复时清理。
- 动态错误内容标记为私有。
- 文件使用 iOS 文件保护。

Android：

- 关闭自动备份。
- 补充云备份排除规则。
- 补充设备迁移排除规则。
- 保留历史文件原位置，不主动删除或迁移。

### 8.4 验证

通过：

- 本地诊断 45 项检查。
- 既有洞察检查 53 项。
- 评分核心回归 1,530 项。
- iOS 完整 Simulator 构建。
- 默认关闭时不生成诊断文件。
- 数据库仍使用原来的默认路径。
- 历史、偏好和诊断目录带备份排除标志。
- 重启后未完成分析计为中断。
- Android 备份配置 9 个存储域检查通过。

尚未完成：

- Android 实际构建。
- Android 备份和恢复实机验证。
- iOS 真机锁屏保护。
- 系统云备份恢复。
- 旧版本备份迁移。

## 9. 本地评分对照实验

### 9.1 目的

在本机比较两种评分规则哪一种更接近用户当次主观自评：

- 当前生产综合分。
- 应用封顶和提升规则之前的连续基础分。

该实验只衡量“更接近自评”，不能证明模型在声学意义上更准确。

### 9.2 主要实现

文件：

- [`PitcheeApp/Diagnostics/LocalScoreStudy.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Diagnostics/LocalScoreStudy.swift)
- [`PitcheeApp/Diagnostics/LocalScoreStudyStore.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Diagnostics/LocalScoreStudyStore.swift)
- [`PitcheeApp/Analysis/ScoreStudyEvaluator.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/ScoreStudyEvaluator.swift)
- [`PitcheeApp/Diagnostics/LocalScoreStudyView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Diagnostics/LocalScoreStudyView.swift)
- [`Tests/Diagnostics/LocalScoreStudyTests.swift`](/Users/dannyfeng/Documents/Pitchee/Tests/Diagnostics/LocalScoreStudyTests.swift)
- [`Scripts/test-local-score-study.sh`](/Users/dannyfeng/Documents/Pitchee/Scripts/test-local-score-study.sh)

行为：

- 独立于基础诊断开关。
- 默认关闭。
- 仅对新录音随机邀请。
- 在显示本次最终分数前询问结构化自评。
- 自评可跳过、超时或选择无法判断。
- 女性向和男性向分开汇总。
- 未选择方向时不询问方向性评分实验。
- 实验不改变正常评分、导出或历史内容。
- 只保存固定汇总，不保存逐次自评和录音的关联。
- 保存九格差值直方图和类别计数。
- 每个 7 天周期最多筛选 100 次、邀请 5 次。
- 关闭或清空后在途反馈不能回写。
- 过期数据清理。
- 使用原子写入、文件保护和备份排除。

### 9.3 验证

- 初始 54 项检查通过。
- 增加版本变化、时钟回退、分析中途清空后达到 59 项检查通过。
- iOS Simulator 编译通过。
- 文案和文档链接检查通过。
- 测试模拟器未能完成实际录音交互验证。

隐私文案已修正：

- 前台通常在 30 秒后继续分析。
- 应用进入后台时系统可能暂停计时，因此不能承诺严格 30 秒。
- 因 A/B 回听功能存在，不能再声称所有音频在分析后立即删除。
- 当前练习音频会保留到练习结束、替换录音或异常恢复。

## 10. 离线研究协议、预算和差分隐私计划

### 10.1 研究文件

- [`Docs/Score-Study-Research-Protocol.md`](/Users/dannyfeng/Documents/Pitchee/Docs/Score-Study-Research-Protocol.md)
- [`Research/score-study-v1.draft.json`](/Users/dannyfeng/Documents/Pitchee/Research/score-study-v1.draft.json)
- [`Research/score_study_protocol.py`](/Users/dannyfeng/Documents/Pitchee/Research/score_study_protocol.py)
- [`Scripts/evaluate-score-study.py`](/Users/dannyfeng/Documents/Pitchee/Scripts/evaluate-score-study.py)
- [`Tests/Research/test_research_protocol.py`](/Users/dannyfeng/Documents/Pitchee/Tests/Research/test_research_protocol.py)
- [`Scripts/test-research-protocol.sh`](/Users/dannyfeng/Documents/Pitchee/Scripts/test-research-protocol.sh)
- [`Docs/Research-Evidence/score-study-utility.md`](/Users/dannyfeng/Documents/Pitchee/Docs/Research-Evidence/score-study-utility.md)

### 10.2 贡献向量

正式评估使用每个安装实例的一次有界贡献：

- 总共 26 维。
- 女性向 13 维。
- 男性向 13 维。

维度包括：

- 收到邀请的安装数。
- 评级、无法判断、跳过、超时和中断比例。
- 分析不可用、失败和中断比例。
- 形成有效配对的安装数。
- 配对覆盖率。
- 两种评分相对自评的平均误差差值。
- 安装间变异，用于样本量规划。

不进入贡献向量：

- 音频。
- 声纹。
- 具体自评等级。
- 曲线。
- 录音标识。
- 时间戳。
- 用户身份。

### 10.3 隐私预算和模拟结果

草案设置：

- 累计 `epsilon <= 2`。
- `delta = 10^-7`。
- 一次发布的计数噪声标准差约 10.1。
- 最多 13 次发布的计数噪声标准差约 36.5。

合成模拟：

- 24 个场景。
- 48,000 次模拟。
- 假设平均改善为 0.5 个自评等级。
- 要求证据支持至少 0.25 个等级的改善。

结果：

| 有效配对安装数 | 一次主要发布 | 最多 13 次发布 |
|---:|---:|---:|
| 100 | 0% | 0% |
| 1,000 | 0% | 0% |
| 5,000 | 100% | 0% |
| 10,000 | 100% | 97.5% |

这些不是模型效果承诺，只适用于当前合成分布和保守阈值。模拟假设约一半受邀安装能形成有效配对，因此 5,000 个有效配对约等于 10,000 个受邀安装。

### 10.4 当前建议

第一轮研究应：

- 只研究一个问题。
- 只比较一个候选规则。
- 使用最长 7 天批次。
- 只做一次主要结果发布。
- 规模不足时继续本地或授权研究。
- 不通过上传明文摘要、延长保留期或放宽隐私预算补足样本。

尚未实现：

- 安全聚合服务。
- 可验证的差分隐私噪声。
- 持久预算账本。
- 不可链接的贡献凭证。
- 重复提交防护。
- 线上参与同意流程。
- 正式上传接口。
- 联邦训练。

后续线程已经计划继续补齐“批次资格、版本绑定、预算预留和重复提交处理”的本地参考接口，但没有在引用线程中完成最终交付。

## 11. 本地化验证和补译

### 11.1 英文标题大小写修改

文件：

- [`Resources/Localizable.xcstrings`](/Users/dannyfeng/Documents/Pitchee/Resources/Localizable.xcstrings)
- [`Docs/Localization-Keys.md`](/Users/dannyfeng/Documents/Pitchee/Docs/Localization-Keys.md)
- [`Docs/Localization-Validation.md`](/Users/dannyfeng/Documents/Pitchee/Docs/Localization-Validation.md)

已修改 146 处英文标题、指标名称、按钮和选项，包括：

- `Average pitch` → `Average Pitch`
- `Overall score` → `Overall Score`
- `Core pitch range` → `Core Pitch Range`
- `Voice details` → `Voice Details`
- `Voice preference` → `Voice Preference`

保留规则：

- `of`、`to`、`and` 等英文介词或连词通常保持小写。
- 法语、西班牙语等语言不机械套用英文 Title Case。
- 德语名词按照当地语法大写。
- `Hz`、`dBFS` 等单位不改变。

### 11.2 编译和覆盖检查

通过：

- 两个字符串目录的 Xcode 编译。
- 29 种语言资源生成。
- 9,344 个字符串单元检查。
- 600 个格式参数检查。
- 复数变体检查。

发现的缺口：

- 英文齐全。
- 简体中文齐全。
- 繁体中文缺 88 条。
- 其他 26 种语言各缺约 160 条。
- 缺口集中在新加入的洞察、评分、诊断、练习、字幕和无障碍功能。

### 11.3 后续补译

用户明确授权：

> 允许按语种并行完成。

之后的计划和操作：

- 按语种启用并行处理。
- 译文先保存为独立文件，避免多个代理同时改写字符串目录。
- 将练习、无障碍、字幕和系统语音识别权限文案纳入范围。
- 统一普通占位符和位置参数。
- 检查数值、隐私承诺、单复数和术语。
- 复核：
  - 最多 5 次邀请。
  - 四分之一邀请概率。
  - 音频路由变化。
  - 检测通过与声音健康的区别。
  - 数值变化与练习进步的区别。
- 新增 [`Scripts/validate-localizations.py`](/Users/dannyfeng/Documents/Pitchee/Scripts/validate-localizations.py)。

线程最后停在“译文已齐、准备合并资源和运行全量校验”的阶段，因此仍应完成：

- 合并最终资源。
- 全量 Xcode 编译。
- 参数和复数检查。
- 逐语言术语审校。
- 真机截断、换行和 RTL 布局检查。

## 12. P0–P2 无障碍改进

### 12.1 目标文件

线程先读取了：

`/Users/dannyfeng/.codex/attachments/08d1ce55-f62d-4251-af8a-16353721f3b2/goal-objective.md`

用户选择了完整范围：

> 完整覆盖 P0–P2，包含进阶体验优化。

### 12.2 已确认的代码修改

主要文件：

- [`PitcheeApp/App/AccessibilitySupport.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/AccessibilitySupport.swift)
- [`PitcheeApp/Analysis/PitchTimeline.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/PitchTimeline.swift)
- [`PitcheeApp/Analysis/LivePitchChartView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/LivePitchChartView.swift)
- [`PitcheeApp/Analysis/RecordingAnalysisView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift)
- [`PitcheeApp/Practice/PracticeCaptions.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeCaptions.swift)
- [`Docs/Accessibility-Checklist.md`](/Users/dannyfeng/Documents/Pitchee/Docs/Accessibility-Checklist.md)
- [`Tests/Recording/PitchTimelineTests.swift`](/Users/dannyfeng/Documents/Pitchee/Tests/Recording/PitchTimelineTests.swift)

已实现：

- 大字号下洞察卡片单列布局。
- 录音栏文字允许换行。
- 大字号日期选择提供列表布局。
- Reduce Motion 下减少或关闭动画。
- 实时音高图表支持按时间浏览历史数据。
- 图表提供可读的 VoiceOver 描述。
- 结果页增加分区转子。
- 钢琴音符支持持续播放和停止的无障碍操作。
- PDF 导出增加可访问文本报告。
- 导出页增加明确的翻页和关闭按钮。
- 练习回放加入本机字幕。
- 字幕不回退到服务器识别。
- 设备或语言不支持本机识别时显示明确提示。
- 回放按钮补充 VoiceOver 名称和错误通知。
- Assistive Access 相关 API 增加可用性判断，以兼容项目部署下限。

### 12.3 验证

通过：

- 图表相关 22 项检查。
- 静音间隔、无效音高、时间窗口检查。
- 实时无障碍图表描述更新检查。
- iOS Simulator 源码快照构建。
- 中文、英文新文案检查。

尚未完成：

- VoiceOver 真机操作。
- Switch Control。
- Assistive Access 实机。
- Screen Curtain。
- 外部辅助输入。
- 本机语音识别实际效果。
- 最大辅助功能字号下所有页面布局。
- 黑屏和模拟器服务问题导致的视觉复验。

## 13. 引导练习实现

### 13.1 主要代码

- [`PitcheeApp/Practice/PracticeData.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeData.swift)
- [`PitcheeApp/Practice/PracticeViews.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeViews.swift)
- [`PitcheeApp/Practice/PracticePlayback.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticePlayback.swift)
- [`PitcheeApp/Practice/PracticeTrendsView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeTrendsView.swift)
- [`PitcheeApp/Analysis/RecordingAssessment.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAssessment.swift)
- [`PitcheeApp/Analysis/RecordingStatistics.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingStatistics.swift)
- [`PitcheeApp/Insights/InsightsData.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsData.swift)
- [`PitcheeApp/Analysis/RecordingAnalysisView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift)
- [`PitcheeApp/Analysis/RecordingView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingView.swift)
- [`PitcheeApp/Analysis/RecordingExportView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift)
- [`PitcheeApp/App/ContentView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift)

### 13.2 数据和流程

每次练习保存：

- 练习类型。
- 目标方向。
- 固定语料。
- 模型版本。
- 评分规则版本。
- 录音质量。
- 原始分析结果。
- 当次综合分快照。
- A/B 对比关系。
- 用户听感反馈。

复练流程：

1. 创建练习上下文。
2. 录制 A。
3. 分析并显示主要反馈。
4. 点击同句复练。
5. 录制 B。
6. 保留 A，替换旧 B。
7. 回听 A/B。
8. 显示数值变化。
9. 用户选择：
   - 更接近目标。
   - 差不多。
   - 无法判断。
10. 结束练习并清理临时音频。

重要语义：

- 音高变化只作为数值差异展示。
- 不自动把数值差异称为进步。
- 质量不足的记录可以显示，但默认不进入趋势。
- 旧记录缺少目标或质量字段时保持未知。
- 修改当前全局目标不能改写历史记录的原始结果。
- “暂不确定”不生成方向性分数。
- 导出内容明确为“导出当时结果”。

### 13.3 质量规则和数据测试

已验证：

- 空数据不会产生虚假的零值中位数。
- 奇数和偶数样本的中位数计算正确。
- 非有限值不进入中位数。
- 不同语料不会混入同一个练习队列。
- 不同模型版本不会混入同一 cohort。
- 不同练习目标不会混合。
- 质量不足的记录不进入默认趋势。
- 缺失音高不影响其他指标的独立统计。
- 旧记录不会被补写目标、质量或方向。
- 备份和编码后 PracticeContext 可恢复。
- 练习结束时清理录音。
- 删除失败会阻止开始下一次录音。
- 真实静音片段可用于背景电平估计。
- 双声道相消仍可检出削波。

### 13.4 已完成和待完成

已完成：

- 29 项练习检查。
- 53 项洞察检查。
- 10,742 项评分回归检查。
- SwiftData 迁移检查。
- iOS Simulator 构建。

待完成：

- 真机实际朗读。
- 录音权限。
- 耳机切换。
- 来电中断。
- 前后台切换。
- 锁屏。
- 临时录音清理。
- 完整 A/B 回听交互。
- 音频删除失败恢复流程。

## 14. 已观察到的构建和验证环境问题

多个线程重复遇到以下环境问题：

- Simulator 安装长时间无响应。
- Simulator 启动后回到关机状态。
- Device Hub 屏幕捕获失败。
- ScreenCaptureKit 错误 `-3811`。
- 截图为黑屏。
- `simctl install` 或 `simctl launch` 超时。
- 多个任务同时修改工作区导致暂时缺少类型或初始化参数。
- SwiftData 初始化 API 参数兼容问题。
- Swift 并发隔离问题，例如在非主 actor 中读取主 actor 状态。
- 独立测试设备系统迁移长时间没有进展。

因此，以下结论要区分：

- **源码/单元测试通过**：可以确认逻辑和数据边界。
- **Simulator 构建通过**：可以确认项目在该构建快照上可编译。
- **Simulator 视觉验证通过**：目前很多页面尚未达到这一层。
- **真机和辅助技术验证通过**：目前尚未达到这一层。

## 15. 已观察到的实际验证命令和脚本

线程中出现过或明确记录过的验证操作包括：

```sh
git diff --check

Scripts/test-practice.sh
Scripts/test-insights.sh
Scripts/test-local-diagnostics.sh
Scripts/test-local-score-study.sh
Scripts/test-voice-scoring.sh
Scripts/test-research-protocol.sh

xcodebuild \
  -project Pitchee.xcodeproj \
  -scheme Pitchee \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/pitchee-practice-build \
  CODE_SIGNING_ALLOWED=NO \
  build

xcrun simctl io <device-udid> screenshot <output-file>.png
xcrun simctl install <device-udid> <app-path>
xcrun simctl launch <device-udid> <bundle-id>
xcrun simctl shutdown <device-udid>
```

已明确报告的自动检查结果：

- Practice：29 项通过。
- Insights：53 项通过。
- Local Diagnostics：45 项通过。
- Local Score Study：59 项通过。
- Pitch Timeline/图表：22 项通过。
- Voice Scoring：1,530 组核心参考数据通过。
- 练习和评分综合回归：10,742 项通过。
- 本地化字符串单元：9,344 项通过。
- 本地化格式参数：600 项通过。
- 研究协议：20 项测试通过。
- 合成研究模拟：48,000 次场景模拟完成。

## 16. 当前工作区状态矩阵

| 领域 | 代码状态 | 自动检查 | Simulator 构建 | 视觉/真机 |
|---|---|---|---|---|
| Recording 按钮 | 已修改 | 通过 | 通过 | 待完成 |
| 分析失败弹窗 | 已修复 | 通过 | 通过 | 待真实交互 |
| Insights 入口 | 已移除 | 通过 | 多次通过 | 待点击验证 |
| About 设置页 | 已完成 | 通过 | 通过 | 部分待复验 |
| 男性向评分 | 已完成 | 1,530 组通过 | 通过 | 公式占位待最终复验 |
| 引导练习 | 大部分完成 | 29/53/10,742 通过 | 通过 | 待真机完整流程 |
| 本地诊断 | 已完成 | 45 通过 | 通过 | Android/锁屏待验证 |
| 本地评分实验 | 已完成 | 59 通过 | 通过 | 录音交互待验证 |
| 研究协议 | 离线工具完成 | 20 通过 | 不适用 | 线上系统未实现 |
| 无障碍 | P0–P2 多项完成 | 图表 22 通过 | 通过 | VoiceOver/真机待验证 |
| 英文大小写 | 已完成 | 通过 | 通过 | 真机排版待验证 |
| 全量本地化 | 初稿和工具进行中 | 部分通过 | 待最终合并 | 待语言审校 |

## 17. 建议的后续执行顺序

### 阶段 A：冻结并合并工作区

1. 暂停并行修改。
2. 在当前工作区建立稳定源码快照。
3. 统一合并：
   - 练习模块。
   - 男性向评分。
   - 本地诊断。
   - 无障碍。
   - 设置页。
   - 本地化资源。
4. 重新执行完整 iOS 构建。
5. 清理暂时性类型、初始化和并发隔离错误。

### 阶段 B：完成练习真机验收

在真实 iPhone 上按以下顺序测试：

1. 首次麦克风权限。
2. 选择练习目标。
3. 朗读固定语料。
4. 查看质量提示。
5. 查看分析结果。
6. 点击同句复练。
7. 播放 A。
8. 播放 B。
9. 记录听感。
10. 导出结果。
11. 结束练习。
12. 确认临时录音被删除。
13. 在分析中切到后台。
14. 锁屏。
15. 来电中断。
16. 拔插耳机。
17. 强制退出后重新启动。
18. 确认未完成练习恢复为中断并清理。

### 阶段 C：完成评分和界面收尾

1. 修复“当前规则”公式占位。
2. 重做男性向、女性向和“暂不确定”的结果页截图。
3. 检查历史、趋势和导出分数一致性。
4. 检查大字体、深色和 RTL。
5. 检查 Recording 原生栏图标比例。

### 阶段 D：无障碍验收

使用真机完成：

- VoiceOver。
- Switch Control。
- Assistive Access。
- Screen Curtain。
- 最大辅助功能字号。
- Reduce Motion。
- 外部辅助输入。
- 本机字幕成功、失败和不可用路径。

### 阶段 E：本地化合并

1. 合并 29 种语言译文。
2. 运行 `validate-localizations.py`。
3. 检查位置参数和复数。
4. 逐语言检查：
   - 标题大小写。
   - 术语一致性。
   - 隐私承诺。
   - 数字和单位。
   - 长文案换行。
   - RTL。
5. 把机器初稿标记为待语言审校，不能直接视为最终翻译。

### 阶段 F：隐私研究准备

1. 继续保持默认仅本机。
2. 明确区分基础诊断和评分实验。
3. 完成贡献限额、批次资格和版本绑定参考实现。
4. 设计安全聚合接口。
5. 设计持久预算账本。
6. 完成独立参与同意。
7. 做威胁建模和隐私审查。
8. 在这些工作完成前，不增加线上上传。

## 18. 最终产品判断

当前最值得继续投入的完整闭环是：

> 固定语料练习 → 录音质量检查 → 本地分析 → 一个主要反馈 → 同句复练 → A/B 回听 → 用户主观比较 → 同类练习趋势。

这个闭环能同时利用已有的：

- 实时音高。
- 录音分析。
- 评分方向。
- 历史趋势。
- 本地诊断。
- 无障碍能力。
- 隐私保护设计。

未来研究数据应继续遵守当前已经确定的边界：

- 音频不上传。
- 不把本地计数直接当作匿名数据。
- 不保存逐次录音和自评的可链接关系。
- 不在样本不足时通过放宽隐私预算制造结论。
- 不把“更接近用户自评”直接描述为“模型更准确”。



## 19. 恢复边界：排除练习线程对首页和结果页的破坏性 UI

在后续恢复中发现，练习线程曾经同时修改首页和结果页 UI。该部分不符合当前产品方向，因此没有直接整树覆盖恢复源，而是采用文件级和 hunk 级选择性恢复。

恢复内容包括练习数据模型、录音质量、男性向评分、本地诊断、隐私保护、无障碍、设置页、本地化资源、研究协议和测试。明确排除：首页练习趋势入口、结果页 practice.compare 工具栏按钮、结果页 PracticeHubView 弹窗、录音页新增的练习工具栏入口。

结果页中与男性向评分有关的目标方向分数、说明、历史和导出保持恢复，因为这些属于评分功能，而不是练习线程带来的破坏性入口。Insights 内部重复录音入口仍按原计划移除，录音统一从 Tab Bar 进入。

本次恢复的完整操作、来源工作树、文件清单、排除项、命令、测试结果和后续验收边界见：[Recovery-Plan-Without-Destructive-UI.md](/Users/dannyfeng/Documents/Pitchee/Docs/Recovery-Plan-Without-Destructive-UI.md)。
