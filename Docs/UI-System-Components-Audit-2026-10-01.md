# Pitchee UI 系统组件复用检查

日期：2026-10-01。范围：当前工作区 Pitchee iOS 应用的 UI 源码，包括未提交的修改；未检查相邻的 Android 项目。

本文保留首次源码审查的发现，后续修改状态见下一节。首次审查检查了主要页面、控件实现及调用关系，并核对 Apple 官方文档和本机 iPhoneSimulator 27.1 SDK。以下优先级表示重构收益，不表示线上故障等级；原始发现中的行号对应替换前的源码。

**结论：四类实现可以优先采用系统组件：活动日历、互斥选项、历史记录列表、导出预览分页指示器。图表存在复用机会，但需要保留业务语义并验证性能。**

## 后续落实状态

用户要求继续后，已经完成以下修改：

| 项目 | 当前实现 |
| --- | --- |
| 声音偏好设置 | [SettingsView.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/SettingsView.swift:155) 使用 inline `Picker`，保留标题、说明文字、自动保存绑定和选项标识，删除手写勾选状态。 |
| 导出预览分页 | [RecordingExportView.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:175) 启用系统分页指示器，多页时为它预留底部空间，单页隐藏；保留页数变化时的页码校正。 |
| 历史与详情列表 | [InsightsDetailViews.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:26) 将共享页面容器改为 `List`，按天使用 `Section`，历史、指标详情和活动详情共用系统导航行，删除手写分隔线及导航箭头。 |
| 活动日历 | [InsightsActivityCalendar.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsActivityCalendar.swift:6) 包装 `UICalendarView`，绑定日期单选与可用日期范围，通过装饰显示打开应用和录音两种状态；保留选中日期的文字状态。 |

删除了旧 `monthCells` 网格算法及其四项专用断言。日期筛选、闰日解析、夏令时、连续天数、记录聚合和评分测试仍保留。

独立 macOS 数据测试原先无法解析新增的 `Color.pitcheeAccent`，现通过 [测试专用主题依赖](/Users/dannyfeng/Documents/Pitchee/Tests/Fixtures/InsightsThemeSupport.swift:1) 补齐；生产应用继续使用原来的主题实现。该测试替身只支持编译数据测试，不用于验证主题颜色。

验证结果：

- 两轮 iOS Simulator Debug 应用构建成功，第二轮包含全部四处替换。
- `Scripts/test-insights.sh`：49 项检查通过。
- 临时验证宿主构建成功，加载实际视图并使用内存中的模拟数据，不修改生产入口或数据。
- 运行时验证未完成：新建模拟器报告已启动，但验证宿主启动请求长时间未返回；截图请求随后返回了一张全黑图片，未显示应用页面。本机常规 Xcode 路径中也未找到 Simulator.app。没有获得日历边界检查的成功结果或可用于检查布局的页面截图，不能将宿主构建成功视为 UI 验证通过。
- 验证设备已清理：本次创建的 `Pitchee native UI verification`（`76F5A2A9-C2C0-4DAE-A014-DC44C735D61C`）删除命令成功返回，设备目录已不存在。没有关闭或删除其他模拟器。

### 待完成的运行检查

以下项目均未标记通过，需要在能够正常启动应用的模拟器或真机上执行：

| 页面 | 操作 | 预期结果 |
| --- | --- | --- |
| 声音偏好 | 依次选择三个选项，离开页面后重新进入；放大系统文字 | 每次只有一个选项选中，保存值与所选项一致，标题和说明完整显示 |
| 导出预览 | 切换单页与多页内容，滑到最后一页后减少导出项 | 多页显示系统分页指示器，单页隐藏；页码保持有效，指示器不遮挡报告内容 |
| 历史与指标详情 | 展开包含多天、多条录音的数据，点击行进入详情并返回 | 日期分组正确，每行显示一个系统导航指示，页面只有一个列表滚动容器 |
| 活动日历 | 在不同月份选择日期，切换时间范围，再检查下方记录 | 高亮日期、日期标题与当天录音一致；缩小范围后选中有效日期，范围外日期不能选择 |
| 日历边界 | 检查首日、末日、闰日、夏令时切换日及只有一天的可用范围 | 边界日期可选、范围外不可选，更新范围不触发 UIKit 异常 |
| 日历活动标记 | 分别显示仅打开、仅录音、两者都有及无活动日期；更新活动数据 | 标记与数据一致，更新后及时刷新，选中日文字状态正确 |
| 无障碍与本地化 | 使用 VoiceOver、辅助功能大字号，以及中英文界面 | 选择状态和活动说明可理解，日期与星期遵循系统设置，控件和说明没有裁切 |

临时验证宿主已准备了 12 项日历断言，但尚未获得执行成功结果。这些断言也不能代替分页手势、列表导航及 VoiceOver 的实际交互检查。

引导页的卡片外观、未接入主导航的练习选择器、实时/导出图表及钢琴触摸逻辑保持原实现。这些项目仍适用下文所述的迁移条件。

## 1. 活动日历：优先采用 UICalendarView

位置：

- [月份导航与日历网格](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:468)
- [日期按钮、活动装饰及选中状态](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:508)
- [补齐月初空格的辅助算法](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsData.swift:197)

当前 `monthHeader`、`calendarGrid`、`dayButton`、`moveMonth` 和 `monthCells` 手动维护翻月按钮、星期顺序、七列网格、空日期单元格、日期范围和选中样式。这些都是系统日历已经提供的能力。

建议用 `UIViewRepresentable` 包装 `UICalendarView`，通过 `UICalendarSelectionSingleDate` 绑定 `selectedDay`，通过 `availableDateRange` 设置可访问日期，通过日期 decoration 显示打开应用和录音状态。系统支持圆点、图片和自定义装饰视图；只有确实需要组合活动标记时才实现小型装饰视图。

需要保留：活动数据计算、连续天数统计、选中日与下方录音列表的联动，以及自定义活动状态的无障碍说明。现有整格橙色背景可以改成系统装饰；若要求逐像素保持该背景，需要另外评估，不能假设系统 decoration 能任意重画日期单元格。

不建议直接换成 `.graphical` 的 `DatePicker`，因为当前需求包括按日期展示活动标记。`UICalendarView` 自 iOS 16 起可用。

## 2. 互斥选项：用 Picker 接管选择行为

当前有四处相同语义的手写实现：

| 位置 | 当前实现 | 建议 |
| --- | --- | --- |
| [声音偏好设置](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/SettingsView.swift:155) | `ForEach` + `Button`，手动赋值、显示 checkmark、补 `.isSelected` | 在现有 `Form` 内使用 `Picker` + `.inline` |
| [引导页声音偏好卡片](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/VoicePreferences.swift:82) | 手动画圆圈、勾选状态、边框和背景 | 若接受系统行式外观，改为 `Picker`；保留选项说明 |
| [练习目标选择](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeViews.swift:18) | 多个按钮模拟一个互斥选择器 | 使用 `Picker`，binding setter 调用 `selectPractice` |
| [练习比较反馈](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeViews.swift:108) | 按钮组手动显示当前反馈 | 使用 `Picker`，setter 保留原保存流程 |

设置页是最直接的替换点：`selection` 已经是 `Binding<VoicePreference>`，无需新增选择状态。选项标题和说明可以保留在选项内容中；根据系统样式的实际渲染效果，也可以把说明移到相邻的说明区域。

引导页必须保留“尚未选择”这一状态。不要为了满足 `Picker` 的初始 selection 而默认选中某个声音方向，否则会改变“先选择才能继续”的流程。可采用可选类型的 selection/tag，或明确的未选择占位项。首次选择即时更新主题及最终保存的行为也需保留。

练习反馈保存有失败回滚逻辑，不能改成只更新本地 `@State`。控件 setter 应调用现有模型方法，并从模型读取保存成功后的值。

调用关系限制：当前源码未发现 `PracticeHubView` 被主导航实例化；它内部使用 `PracticeSetupView` 和 `PracticeResultPanel`。因此练习页两项属于已有代码的重构候选，不能当作当前可访问主界面的已验证体验问题。`ScoreStudyFeedbackView` 的评分按钮点击后立即提交并离开，该语义是操作，不应机械替换为需要确认的选择器。

## 3. 历史记录：用 List + Section 承担列表结构

位置：

- [按天分组的历史页面](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:127)
- [InsightsRecordingList](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:164)

当前用 `LazyVStack` 绘制列表，手动添加每行的 `chevron.right`、分隔线、分隔线前导缩进、行内边距和分组背景。数据按天分组并点击进入详情，符合系统分组列表的用途。

建议将历史页面的滚动根容器改为 `List`，日期使用 `Section`，行继续使用 `NavigationLink`，配合 `.listStyle(.insetGrouped)`。记录图标、数值、时长等内容仍可保留自定义布局，系统负责列表行的容器行为和导航指示。

注意：外层 `InsightsPage` 当前已经包含 `ScrollView`。不能只把内层 `LazyVStack` 换成嵌套的 `List`；需要让历史页使用独立列表容器，或把通用页面拆成列表与卡片两种组合。该列表也用于指标详情与活动详情，应抽取可复用的“行内容”，避免在每个嵌入位置制造独立滚动区。

相似但收益较低的地方是 [分析建议分组](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:228)：同样手动添加分隔线和分组背景。如果结果页整体转成分组列表，可使用 `Section` + `Button`，继续展示原来的 sheet。只有两条建议时，为此单独嵌入一个 `List` 并不划算。

首页网格卡片里的导航箭头不列为直接替换项：卡片位于自定义网格，系统没有等价的现成仪表盘卡片组件。

## 4. 导出预览：启用 TabView 自带的分页指示器

位置：[导出预览的 TabView 和手写圆点](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:163)。

当前已经使用 `.page` 风格的 `TabView`，却通过 `indexDisplayMode: .never` 关闭系统指示器，再在第 183 行之后用 `ForEach` + `Capsule` 手动画圆点、选中长度、颜色和切换动画。这是最明确、改动最小的重复实现。

建议启用 `.page(indexDisplayMode: .automatic)` 或按页数选择显示模式，并按背景对比度需要设置 `.indexViewStyle(.page(backgroundDisplayMode: .always))`。删除额外的圆点布局；预览内容、selection binding、分页数据模型继续保留。`normalizePreviewIndex()` 处理导出内容变化后页数减少的问题，仍然需要。

代价是采用系统圆点外观，不再保留选中项拉长为胶囊的视觉设计。`PageTabViewStyle` 自 iOS 14 起可用。

[引导页也绘制了分页胶囊](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/OnboardingView.swift:115)，但它表示 `NavigationStack` 中受校验约束的两个步骤，不能直接照搬分页 `TabView`。可在接受视觉变化时采用文本步骤提示、`ProgressView` 或小型 `UIPageControl` 包装；该项收益低于导出页。

## 5. 自绘图表：可替换一部分，但先验证

| 位置 | 重复的基础能力 | 迁移条件 |
| --- | --- | --- |
| [PitchPlot](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/LivePitchChartView.swift:48) | Canvas 手画坐标轴、刻度、网格、折线、坐标映射和裁剪 | 可用 Swift Charts、`LineMark` / `LinePlot`、对数纵轴和 `AxisMarks`；必须验证实时刷新成本 |
| [ExportCurvesChart](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:926) | 再次实现坐标轴、刻度、折线、图例；另有 `linePath` | 当前同图展示 Hz 与 dBFS 两个独立量纲；迁移需要处理轴映射或调整为多个图，不能承诺直接等价替换 |
| [PitchGenderScale](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:1130) | 手动归一化均值和区间、计算标记坐标 | 若统一为图表样式，可考虑区间 mark 与均值 rule；现有玻璃区间和竖向外观是产品定制，普通 Gauge 并不等价 |

`PitchPlot` 的替换方向最清楚。项目其他趋势页面已经使用 Swift Charts；`LinePlot` 自 iOS 18 起可用，可作为密集数据的候选实现。迁移后仍应按无声样本和时间间隔拆分连续序列，不能简单过滤 nil 再连成一条线；原来的对数坐标、75–600 Hz 范围、实时窗口和图片导出也需要保留。

本次没有性能测试，不能断言 Charts 比 Canvas 更快。已有 `PitchChartDescriptor` 是系统无障碍图表适配代码，但静态搜索显示它只在测试中被使用，不能据此认定实时图已接入完整图表无障碍。采用 Charts 后仍需检查外层 `.accessibilityElement(children: .ignore)` 是否屏蔽了需要暴露的数据。

## 6. 低收益统一项与合理定制

[首页 emptyState](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:576) 单独排版空状态；项目在 [InsightsEmptyState](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:86) 已经包装了系统 `ContentUnavailableView`。若希望统一空状态外观，可复用该模式，但这只是较小的风格收敛收益。

以下实现有合理用途，本次不建议作为“重复造轮子”直接移除：

- [PianoKeyTouchSurface](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:787)：已经使用系统长按手势，需要按下即发声、松开及取消时停止、与外层滚动同时识别，以及视图拆除时清理。普通 `Button` 的点击事件不覆盖这些要求。
- [FoldAwareArrangementView](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/FoldAwareArrangementView.swift:30)：封装并调用系统布局 API，属于适配层。
- [AccessibleStack](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/AccessibilitySupport.swift:22)：基于系统 `AnyLayout` / StackLayout 选择布局，属于有意义的无障碍组合。
- [RecordingTabAccessory](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingTabAccessory.swift:17)：已经使用系统 `tabViewBottomAccessory`。
- 设置页的 `Form`、`ColorPicker`、`Toggle`，导出页的 `List(selection:)`、`fileExporter`，以及现有的 `TabView`、`NavigationStack`、sheet、alert、`ProgressView` 均在复用系统组件。
- 玻璃效果 modifier 调用的是系统 `glassEffect`；卡片图标及背景包装、报告固定纸张排版、声音比例气泡没有必要仅因“自定义”就全部替换。

## 建议落地顺序

1. 先处理导出分页指示器与声音偏好设置的 `Picker`，改动范围小。
2. 再迁移活动日历，核对月份边界、日期范围、活动标记、系统日历及 VoiceOver 状态说明。
3. 重组历史页为 `List` + `Section`，同时保留指标页与活动页对行内容的复用。
4. 对 `PitchPlot` 做等价原型，验证空值断线、实时性能和导出效果后再决定是否迁移。
5. 练习页面进入主导航时，再统一其选择控件。

## 核对过的官方资料

- [UICalendarView](https://developer.apple.com/documentation/uikit/uicalendarview)：日期装饰及单选、多选支持。
- [Picker](https://developer.apple.com/documentation/swiftui/picker)：互斥值选择控件。
- [PageTabViewStyle](https://developer.apple.com/documentation/swiftui/pagetabviewstyle)：系统分页 TabView。
- [LinePlot](https://developer.apple.com/documentation/charts/lineplot)：集合数据的连续折线图表内容。
