# Pitchee 练习、知识库与趋势详情：ADA Skill 代码设计审查

审查日期：2026-10-06。审查对象：`/Users/dannyfeng/Documents/Pitchee` 当前工作区，包含未提交改动。只读应用源码和本地资源；未使用模拟器、未构建、未修改应用。本文是结构、内容、组件状态和静态导航审查，不是当前渲染截图或真机交互验收。

采用用户提供的 [ada-interaction-design/SKILL.md](/Users/dannyfeng/Downloads/ada-interaction-plugin/skills/ada-interaction-design/SKILL.md)，并读取 `visual-system.md`、`visual-review.md`、`component-craft.md`、`swiftui-craft.md`、`motion-craft.md`。主要标准是：第一焦点、稳定读法、内容先于装饰、组件状态完整、图形与数据语义一致、跨页对象连续性。Skill 中的要求是参考材料；本次用户明确要求先不用模拟器，因此没有执行其运行验收流程。

## 结论

在这一组视图中，最影响体验的不是圆角、阴影或系统 List，而是“练习目标 → 读懂反馈 → 找到对应方法 → 实际练一次”的路径不连续，以及同一记录/指标在不同页面改变解释方式。知识库的实际 reader 已经比旧版卡片样式克制，段落、表格、公式也有真实实现；不宜一概判成“没有设计”。现存的若干复杂 A/B 和可信趋势视图未接入当前产品路径，不能用它们的代码推断用户正在看到的画面。

优先级含义：P1 是当前核心承诺无法在导航中完成；P2 是经常造成理解成本或跨页不一致；P3 是局部语义/细节完善。尺寸裁切、对比度和动效性能等没有运行证据的事项单列为待验证，不伪装成实测缺陷。

## 实质发现

### PI-01 · P1 · 可见文章承诺 App 内 A/B 练习，但当前导航没有入口

- 位置：当前 [PracticeRoute](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeHubView.swift:3) 仅有 scoring、analysis、pitch、spectrum、spectrogram；[练习入口列表](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeHubView.swift:33) 也只有四个检测工具。全工作区 Swift 实例调用检索发现 `GuidedPracticeSessionView` 只有定义，没有调用；`PracticeSetupView` 和 `PracticeResultPanel` 仅从这个未接入的根视图调用。
- 当前内容证据：[bundled 文章 JSON 第 41 行](/Users/dannyfeng/Documents/Pitchee/Resources/VoiceTrainingLibrary/voice-training-library.json:41) 明确写“在 App 的 A/B 复测中，使用当次固定文本”；[第 1842 行](/Users/dannyfeng/Documents/Pitchee/Resources/VoiceTrainingLibrary/voice-training-library.json:1842) 解释“当前 iOS A/B 回听音频”和反馈选项。扫描 49 篇实际资源，11 篇含“App 的 A/B / 当前 iOS A/B / 当前 iOS 引导练习”这类当前产品表述。
- 用户影响：用户从教程接受一个明确的练习建议，却无法找到文中所说的流程。界面会让人怀疑自己漏掉了入口，阅读也不能自然转为行动。
- 改法：先决定当前产品是否保留 A/B。保留就将现有流程接到一个清楚的练习入口，并让相应教程携带练习上下文进入；暂不提供则将文章中的“当前 App 已有”表述改为可独立完成的方法，避免继续指向不存在的功能。不要为了审美重新造一套旧流程。
- 证据边界：这是当前静态导航图及实际内容间的不一致；未声称曾在设备上点击复现。

### PI-02 · P2 · “练习”入口先要求用户选择检测工具与技术分类

- 位置：[PracticeHubView.swift:33](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeHubView.swift:33) 的第一组是“实时检测”，顺序是评分、实时基频、实时频谱、Spectrum；下一组遍历 `store.categories`。类别来自 [VoiceTrainingLibrary.swift:371](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/VoiceTrainingLibrary.swift:371) 的模块 ID 字典序，首先是“算法规则判定”“综合得分区间”“声学单项指标”，再到具体方向和引导练习，分类显示名在 [141 行](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/VoiceTrainingLibrary.swift:141)。中文 `practice.spectrum.title` 当前仍为 `Spectrum`。
- 用户影响：若此页的首要任务是练习声音，初次用户需要先知道 F0、实时频谱、Spectrum 和评分有什么区别，再自己从分类中拼出下一步。没有错误操作，但决策成本高；各项同权重，没有推荐起点或用途说明。
- 改法：保留系统 List 和现有检测工具，在工具名下加一句任务用途；将“开始一次短练习/了解当前声音”设为明确起点，再把进阶仪表、知识库分类作为支持路径。分类顺序按用户问题安排，算法解释作为可进入的知识主题。给实时频谱与 Spectrum 使用能说明不同任务的名字。
- 不应误报的点：搜索提示已经明确写“搜索知识库”，因此搜索只搜文章本身不算实现错误。它仍可以保持此范围；不必为了统一而强行变成全局搜索。

### PI-03 · P2 · 历史列表与历史详情使用不同的声音目标解释同一份结果

- 位置：[InsightsRecordingRows](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:137) 从当前设置读取 `voicePreference`；[173–176 行](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:173) 用当前目标计算分数和标题。打开详情时，[195 行](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:195) 却将 `assessment.recordedTarget` 传给 `RecordingResultView`；[RecordingAnalysisView.swift:107](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:107) 优先采用录制时目标。分数确实会重新计算，见 [RecordingAssessment.swift:109](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAssessment.swift:109)。
- 触发：录制时采用方向 A，之后在设置里改为方向 B，再查看这条历史记录。
- 用户影响：点同一条记录，列表和详情的方向名称/分数可能改变。用户看到的是一次普通导航，却需要猜测评分口径为何变化，削弱对整个数据系统的信任。
- 改法：默认列表、详情保持同一口径；需要按当前目标重评时，显式标记“按当前目标查看”，让详情继承同一选择。录制时目标可作为元数据展示。不要把口径变化藏在页面实现细节中。

### PI-04 · P2 · 指标色彩在首页与详情之间换义

- 首页综合分数字蓝色、曲线紫色，见 [ContentView.swift:365](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:365) 和 [391 行](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:391)；首页自然度紫色、音高青色，见 [503 行](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:503) 和 [518 行](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:518)。
- 详情统一使用 [InsightsMetric.tint](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsData.swift:78)，其中自然度青色、音高橙色、综合分主题色；实际用于标题、数字、曲线和列表行，见 [InsightsDetailViews.swift:332](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:332)。
- 用户影响：首页建立的“青色=音高”记忆进入详情变成“青色=自然度”。多色增加注意力消耗，却未提供稳定的分类线索。
- 改法：首页与详情直接共享指标样式映射；同一个指标的标题/数字/曲线一致。使用次数这类辅助统计可采用中性文字，使指标色真正成为有用的记忆线索。

### PI-05 · P2 · 音高的涨跌被红绿翻译成褒贬

- 位置：[ContentView.swift:650](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:650) 对所有指标统一设为上升绿、下降红；音高卡也使用 [585 行的 trendText](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:585)。
- 用户影响：希望探索较低声音的人，可能正在接近目标，却反复收到红色下降反馈。它和详情解释中的“数值较高并不等同于声音更好”也不一致。
- 改法：物理量变化用中性箭头、Hz 和明确比较对象；仅在存在可靠目标区间且能判断接近/远离时使用评价颜色。分数与物理量不要共用未经区分的格式器。

### PI-06 · P2 · 从“下一步建议”打开文章后，读者仍需从背景开始自行寻找操作部分

- 位置：结果页的 [PracticeSuggestionsSection](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeSuggestionsSection.swift:16) 将建议链接到完整文章；[VoiceArticleContentView 的 body（750 行）](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/VoiceTrainingLibrary.swift:750) 固定依次显示 header → context → 所有章节。所有 49 篇文章均采用“理解这项主题 → 练习前的观察 → 可尝试的方法 → 依据与延伸阅读”，[861 行](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/VoiceTrainingLibrary.swift:861) 按顺序渲染，无章节跳转、指定建议锚点或返回练习动作。
- 内容量证据：方法部分前的正文通常约 324–654 字符，连续评分文章 2175 字符，F1–F4 文章 1276 字符，还不包括大标题、摘要与适用情况。这里是字符计数，不是实测“要滚几屏”。
- 用户影响：从百科浏览进入文章时顺序合理；从具体建议进入时，用户的意图是做一个动作，却再次进入一篇需要重新定位的长阅读。教程有内容，但“看到建议”到“照着做”之间仍有负担。
- 改法：保留完整内容和安全/适用前提，增加简洁的章节目录或“查看方法”锚点；建议入口可携带相关 section。将一条具体方法与录音/比较入口相连。健康或机制主题不强行添加“开始练习”按钮。

### PI-07 · P3 · 文章有序步骤的数字被明确从辅助功能树隐藏

- 位置：[VoiceTrainingLibrary.swift:1322](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/VoiceTrainingLibrary.swift:1322) 的 `numberedItem` 将显示的步骤数字设为 `.accessibilityHidden(true)`，而正文没有补回“第几步”的组合标签。实际资源 23 篇文章共含 108 个此类编号条目。正文子标题 [1258 行](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/VoiceTrainingLibrary.swift:1258) 也未像外层章节标题那样添加 header trait。
- 用户影响：代码会移除供读屏使用的步骤数字，视听读法不一致；中途回到某一步或按步骤复述时缺少编号线索。尚未运行 VoiceOver，不声称整篇文章不可读。
- 改法：将编号和正文合并为有明确序号的可访问元素，保留步数语义；对子标题添加 header trait。不要只让装饰样式看起来像编号/标题。

## 不作为已实测缺陷的代码覆盖缺口

1. **Insights 大字号布局没有和已有辅助布局组件接轨。** `InsightsRangePicker` [21 行](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:21) 固定 segmented；历史汇总 [111 行](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:111)、图表摘要 [357 行](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:357)、活动摘要 [433 行](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:433) 都固定三列 HStack；主数字 [342 行](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:342) 固定 44 pt，并用缩字缓解空间。项目已有 [AccessiblePickerStyle / AccessibleStack](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/AccessibilitySupport.swift:20)，这些详情没有复用。建议复用并验证小屏/最大字号；目前只确定缺少显式重排策略，不声称已经裁切。
2. **Reader 的公式、表格在真实设备上的可读性未验证。** 10 个 display 公式、5 张表格均有横向滚动容器与滚动提示；不能根据源码宣称公式被截掉，也不能根据修饰符存在宣称已解决。还需检查 LaTeX 包对公式的 VoiceOver 表述、链接点击和混合排版。
3. **图表拖动连续性未验证。** `chartXSelection` 使用系统 Charts、更新选中读数并在 range/preference 改变时清空选择；代码方向合理。未操作，不能声称无抖动或每秒多少帧。
4. **日历标记的实测可访问性未验证。** 代码提供圆点/波形两种形状、图例、状态文本与自定义 accessibilityLabel，已经避免只靠颜色；需设备核对 UIKit date cell 和装饰的合并播报，不将 5 pt 圆点直接认定为触控目标不合格，因为点击目标是系统日期格。
5. **历史图表的代表记录口径值得产品确认。** 自然度和音高也按“综合分最高的当天录音”取样，说明文字确实在详情中交代，并非假数据。改变声音目标后可能换一天中的代表录音。可以在图表旁更早提示“每天取综合分最高的一次”，但不在没有产品意图依据时直接判为算法错误。

## 逐文件、逐视图覆盖与保留项

| 文件与视图 | 当前可达性 | 已检查范围 | 应保留的设计/实现 |
|---|---|---|---|
| [PracticeHubView.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeHubView.swift:1)：PracticeHubView、PracticeRoute | 主 Tab 实际入口；value route 由 MainTabView 接收 | 默认工具/分类列表、知识库搜索、零搜索结果、命名/顺序 | 系统 List / NavigationLink；搜索提示明确范围；空搜索有 ContentUnavailableView；无重复手工 chevron |
| [PracticeViews.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeViews.swift:11)：PracticeSetupView | 只由未接入的 GuidedPracticeSessionView 引用 | 可配置选择、已选练习说明、固定文本、录音指导、结束按钮 | 选择态同时有图标与 isSelected；正文语义字体；固定朗读文本可支持可比性。当前不可达，不把旧界面的重复信息列作现状问题 |
| 同文件：RecordingQualityView（54） | 无实例调用 | 可比/排除、质量问题、缺失旧数据、背景未测量 | 标题、图标和说明共同表达结果；没有仅依赖青/橙色。不可达，不计入当前屏幕问题 |
| 同文件：PracticeResultPanel（80）、takeRow（162）、comparison（210） | 只由未接入的 GuidedPracticeSessionView 引用 | 一次/两次录音、播放/停止、字幕生成/取消/错误、比较/不可比、主观反馈、再录/结束、前后台和消失清理 | 明确不把差值直接宣称为效果；回听和“无法判断”反馈有价值；相关错误有 accessibility announcement；AccessibleStack 已支持重排。尚未接入，不能据其外观评价现状 |
| 同文件：RecordingContextView（240） | 无实例调用 | 录制目标、旧数据、练习类型、评分版本、比较反馈 | 这些元数据对解释历史口径有用；可用于 PI-03，但不建议全部提升到主视觉 |
| [PracticeSuggestionsSection.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeSuggestionsSection.swift:4) | 当前 RecordingResultView 的 236 行实际调用；旧 A/B 也引用 | 最多两条、可打开文章/无文章、标题正文和分隔、整行命中区 | 两条上限有效降低负担；无文章仍保留可执行文案；可操作项有 chevron、不可操作项没有；应保留克制的行式结构 |
| [PracticeTrendsView.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeTrendsView.swift:11) | 无实例调用，非当前首页趋势；未发现 Preview | cohort/目标/指标选择、中位数/最佳切换、空状态、图表、每日数据、方法披露 | 将可比条件、每日范围和中位数说清楚；详情披露而非全部展开；不自动把上下变化解释成好坏。若恢复应维持这些语义 |
| [GuidedPracticeSessionView.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/GuidedPracticeSessionView.swift:14) | 无实例调用；注释所说录音工具栏入口已不在当前导航 | 等待评分研究反馈、分析中、练习结果、设置、关闭与录音 toolbar | 现有状态分支是可复用基础；未运行关闭/取消流程，不声称其清理正确。主要问题是 PI-01 的接入和内容承诺 |
| [VoiceTrainingLibrary.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/VoiceTrainingLibrary.swift:18)：LibraryTheme、VoiceArticle、Store、Matcher | 为所有真实知识库界面提供数据 | 49 篇/8 类资源、分类顺序、搜索字段、文章匹配、建议数量、颜色角色、缺资源时空数组 | 使用本地资源；搜索标题/摘要/目标/正文；建议先看采集质量并至多两条；探索目标不会强行继承二元方向；这些比随机卡片装饰更重要 |
| 同文件：VoiceArticleDetailView（724） | 从当前结果页建议 sheet 可达 | NavigationStack、关闭、复用 reader | 同一阅读内容复用为 push/sheet，避免两套文章排版 |
| 同文件：VoiceArticleContentView（746）、articleHeader（780）、contextSection（817）、sectionsList（861） | 从搜索、类别文章列表、建议实际可达 | 标题/分类/阅读时间/摘要/适用情况/目标、4 章、分享、各级标题、正文宽度与留白 | 680 pt 阅读宽度约束；正文 `.body`；真实内容定义视觉主体；章节 title2 + separator；没有给每段加圆角卡。PI-06 是任务入口问题，不是否定整篇阅读布局 |
| 同文件：VoiceTrainingLibraryBrowserView（889） | 当前结果页“全部知识库”sheet 可达 | 独立 NavigationStack、可选关闭按钮 | sheet 边界明确，复用 content |
| 同文件：VoiceTrainingLibraryContentView（917）、emptyStateView（996） | 从练习分类 push / 完整知识库 sheet 可达 | 分类筛选/搜索、文章数、分组、空结果、清除搜索/查看全部 | 筛选、空结果恢复动作完整；使用系统列表；filter 有 accessibilityValue |
| 同文件：VoiceLibraryListRow（1026）、AdaptiveRowStack（1056） | 真实文章列表可达 | 文章图标/标题/阅读时间；辅助功能字号改为 VStack | 默认简洁，图标装饰隐藏；大字号取消标题两行限制并重排。当前最长文章标题 26 字符，未实测裁切，不把两行限制自动算问题 |
| 同文件：VoiceArticleRowView（1071） | 无实例调用 | 彩色图标底座、分类/阅读时间/摘要/chevron 的旧卡片 | 这是未接入组件。不能据此声称当前列表仍是“每行一个彩色卡片”；真实列表是上面的 VoiceLibraryListRow |
| 同文件：RichInlineText（1137）、math normalization（1178–1215） | 文章正文、表格、子标题实际可达 | 普通 Markdown、inline math、完整 display math、delimiter 归一化、无 LaTeX 包回退 | 完整 display math 才采用自身横向滚动；可见滚动条；template 颜色；文本选择。未验证公式辅助功能/运行布局 |
| 同文件：ArticleBodyView（1220）、renderElement（1256）、tableCell（1349） | 所有文章章节实际可达 | 子标题、表格、无序/嵌套条目、有序条目、段落、分隔线；表格范围和 header trait | 正文 body、段距与行距；表格允许横向滚动，列宽相对字体缩放；表头有标记；PI-07 改善步骤和子标题语义 |
| 同文件：ArticleBodyParser（1364） | 支撑上面实际 renderer | 逐行解析、稳定 element ID、文档缓存、更新源文本 | 每个 mounted section 缓存一次文档；当前所有资源的 display math 均单行完整，因此不能把“逐行解析不支持多行公式”的未来限制当当前文章错误 |
| [InsightsDetailViews.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:12)：InsightsRangePicker、InsightsPage、InsightsCard、InsightsStat、InsightsEmptyState | 首页及历史/指标/活动详情实际可达 | 时间筛选、列表壳、统计值、空状态、表面语义 | 原生控件/列表适合这些任务；范围 selection 共享；正文不靠装饰分组。显式大字号重排覆盖不足单列待验证 |
| 同文件：RecordingHistoryView（97）、InsightsRecordingRows（133） | 首页分析次数卡进入 | 统计总数/天数/语音时长、日分组、时长/分数、空记录 | 日期分组和真正的 NavigationLink；语义日期/Duration；PI-03 统一评分口径，PI-04 统一颜色 |
| 同文件：RecordingHistoryDetailView（189） | 历史/活动/指标列表行进入 | 完整结果复用、历史缺失数据、导出、标题时间 | 缺失结果有明确 unavailable；复用结果视图。历史详情刻意使用录制目标本身合理，应与列表一致 |
| 同文件：InsightsMetricDetailView（216）、InsightsMetricChartData（264）、InsightsMetricChartCard（314） | 首页综合分/自然度/平均音高卡进入 | 每日代表数据、最新/已选读数、单位/时间、图表/选择、平均最小最大、解释、空值、记录列表 | 相比首页，单位/时间/选择状态更完整；图表和列表可交叉阅读；缺失保持缺失，不伪装 0；`variation` 分支当前无实际入口，不把它的兜底纵轴域视为当前 bug |
| 同文件：InsightsActivityView（405） | 首页打开天数卡进入 | 打开/录音/连续天数、筛选、日历、图例、选中日状态与记录、日期范围 | 圆点/波形 + 文案区分活动类型；真实系统日历；共享筛选/日期状态，空日有说明 |
| 同文件：InsightsDetailPreview（496）及 5 个 Preview | 仅 DEBUG Preview wrapper | history/activity/composite/naturalness/pitch-empty 数据接线 | 与真实视图共用内容；Preview 不能当运行验收证据 |
| [InsightsActivityCalendar.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsActivityCalendar.swift:6)：UIViewRepresentable、Coordinator、marker | 仅通过实际 InsightsActivityView 可达 | locale/calendar/timeZone、日期上下界、选中日同步、范围变更、差量装饰更新、布局 sizeThatFits、文字可访问性 | 系统拥有月份导航/日期格/选择；更新时避免旧范围非法日期；不让装饰单独承担交互目标；形状与状态文案充分，保留 |

## 真实文章资源覆盖

审查使用 [Resources/VoiceTrainingLibrary/voice-training-library.json](/Users/dannyfeng/Documents/Pitchee/Resources/VoiceTrainingLibrary/voice-training-library.json:1)，不把 Docs 中旧文件名作为当前界面标题。当前 49 篇文章的显示标题已经多处重写，旧文件名仍含的“黄金频段”“拯救”等词不能直接据此指责当前 UI 文案。

所有 49 篇均有相同 4 章结构。资源整体含 5 张两列表格、10 个独立 display 公式（分布于 2 篇文章）、23 篇包含合计 108 个有序条目。以下完成逐文章的标题、章节结构和渲染类型扫描，不等于重新进行每篇医学/研究论据审查。

| ID | 当前显示标题 | 渲染边界 |
|---|---|---|
| RULE-CONTINUOUS-01 | 读懂连续评分：音色分、自然分与音高怎样参与计算 | 4 章、正文/链接；表格；display 公式；行内数学；有序步骤 |
| RULE-F0-UNAVAILABLE-01 | 音高没有检出：先检查录音，再区分耳语与有声发音 | 4 章、正文/链接；有序步骤 |
| RULE-F0-UNAVAILABLE-02 | 从呼气到有声短句：探索轻松的发声起始 | 4 章、正文/链接；有序步骤 |
| RULE-HIGH-F0-MALE-01 | 音高与音色分不同步：理解女性向 59 分上限 | 4 章、正文/链接；有序步骤 |
| RULE-HIGH-F0-MALE-02 | 元音与音色变化：在清晰表达中探索不同听感 | 4 章、正文/链接；有序步骤 |
| RULE-HIGH-F0-MALE-03 | 音色、听感重量与表达风格：寻找自己喜欢的组合 | 4 章、正文/链接；有序步骤 |
| RULE-HIGH-F0-STYLIZED-01 | 音高较高、自然分较低：理解 30 分上限 | 4 章、正文/链接；有序步骤 |
| RULE-HIGH-F0-STYLIZED-02 | 半封闭声道练习：把唇颤或吸管发声作为可选尝试 | 4 章、正文/链接 |
| RULE-HIGH-F0-STYLIZED-03 | 认识 M1、M2 与听感重量：不靠分数给声带分类 | 4 章、正文/链接；有序步骤 |
| RULE-LOW-F0-NATURAL-01 | 探索稍高的音高：从舒适短音接回说话 | 4 章、正文/链接；有序步骤 |
| RULE-LOW-F0-NATURAL-02 | 保留偏好的音高：同时理解整体听感与算法上限 | 4 章、正文/链接；有序步骤 |
| RULE-LOW-F0-STYLIZED-01 | 理解 20 分上限：把模型结果与身体感受分开 | 4 章、正文/链接；有序步骤 |
| RULE-LOW-F0-STYLIZED-02 | 练习前后如何放松：可选的轻叹与自然停顿 | 4 章、正文/链接；有序步骤 |
| RULE-PASS-BOOST-01 | 理解 pass_boost：从短句尝试过渡到较长表达 | 4 章、正文/链接；display 公式；有序步骤 |
| RULE-PASS-BOOST-02 | 把偏好的声音带入生活：允许情绪与场景变化 | 4 章、正文/链接；有序步骤 |
| SCORE-ADVANCED-01 | 从朗读走向聊天：探索适合情境的自然表达 | 4 章、正文/链接 |
| SCORE-ADVANCED-02 | 语速、重音与停顿：让节奏服务于你想表达的意思 | 4 章、正文/链接 |
| SCORE-MASTER-01 | 把满意声音带入生活：迁移、休息与表达灵活性 | 4 章、正文/链接 |
| SCORE-MASTER-02 | 长期用声照护：水分、负荷与反流相关疑问 | 4 章、正文/链接 |
| SCORE-MID-01 | 让满意的尝试更容易重现：听觉反馈与练习提示 | 4 章、正文/链接；有序步骤 |
| SCORE-MID-02 | 安排练习节奏：让短时尝试与休息适合你的日常 | 4 章、正文/链接；有序步骤 |
| SCORE-STARTER-01 | 从第一次录音开始：选择一个清楚、可重复的练习目标 | 4 章、正文/链接；有序步骤 |
| SCORE-STARTER-02 | 回听带来压力时：把声音观察与自我评价分开 | 4 章、正文/链接；表格 |
| METRIC-DURATION-SHORT-01 | 录音太短或一句话说不完：分别处理录音与换气 | 4 章、正文/链接 |
| METRIC-NATURAL-LOW-01 | 理解自然分：日常说话听感与风格化表达 | 4 章、正文/链接；有序步骤 |
| METRIC-NATURAL-TENSION-01 | 练习后发紧或酸痛：如何调整，以及何时寻求评估 | 4 章、正文/链接 |
| METRIC-PITCH-HIGH-01 | 音高较高时：寻找适合自己与情境的说话范围 | 4 章、正文/链接 |
| METRIC-PITCH-MONOTONE-01 | 探索语调变化：保留普通话声调，也表达自己的意思 | 4 章、正文/链接 |
| METRIC-PITCH-UNSTABLE-01 | 理解音高波动：区分语调、非自愿变化与追踪误差 | 4 章、正文/链接；有序步骤 |
| METRIC-VFP-DARK-01 | 从音色探索到单元音分析：认识 F1–F4 共振峰 | 4 章、正文/链接；表格；有序步骤 |
| METRIC-VFP-NASAL-01 | 鼻音与明亮感：分清正常鼻化、鼻塞和音色选择 | 4 章、正文/链接 |
| METRIC-VFP-THIN-01 | 声音偏轻时：探索清晰度、响度与个人喜欢的质感 | 4 章、正文/链接 |
| METRIC-VOLUME-PROJECTION-01 | 让别人听清：响度、距离与声音投射 | 4 章、正文/链接；有序步骤 |
| MASCULINE-BASICS-01 | 男性向声音探索：音高、音色与表达方式 | 4 章、正文/链接 |
| MASCULINE-INTONATION-01 | 男性向表达中的语调与重音选择 | 4 章、正文/链接 |
| MASCULINE-LARYNX-01 | 探索较低声音时，怎样减少用力与压喉 | 4 章、正文/链接 |
| MASCULINE-ON-T-01 | 使用睾酮期间的嗓音变化与照护 | 4 章、正文/链接 |
| MASCULINE-PRE-T-01 | 未使用睾酮时的男性向声音探索 | 4 章、正文/链接；有序步骤 |
| NONBINARY-EXPLORE-01 | 中性与多元声音：按自己的目标探索 | 4 章、正文/链接；表格；有序步骤 |
| NONBINARY-FLUIDITY-01 | 在不同场景使用不同声音：练习切换与保留选择 | 4 章、正文/链接 |
| PRACTICE-AB-DROP-01 | A/B 复测分数下降：先确认变了什么 | 4 章、正文/链接 |
| PRACTICE-AB-SUBJECTIVE-01 | 听感更接近目标，分数却没变：怎样使用这次反馈 | 4 章、正文/链接 |
| PRACTICE-AB-UNSURE-01 | 回听时无法判断：把问题缩小，再决定要不要继续 | 4 章、正文/链接 |
| QUALITY-CLIPPING-01 | 录音提示可能削波：先调整采集，再比较声音 | 4 章、正文/链接 |
| QUALITY-ENVIRONMENT-01 | 电平过低或背景干扰：让录音条件更可比 | 4 章、正文/链接 |
| HEALTH-CLINICAL-01 | 何时寻求嗓音支持，如何准备就诊 | 4 章、正文/链接 |
| HEALTH-HYGIENE-01 | 日常嗓音照护：补水、休息与用声安排 | 4 章、正文/链接 |
| HEALTH-REDLINE-01 | 练声后出现疼痛、嘶哑或失声时怎么办 | 4 章、正文/链接 |
| HEALTH-TWVQ-01 | 认识 TWVQ-SC：记录嗓音与生活体验 | 4 章、正文/链接；表格 |

## 本组建议优先顺序

1. 先修复当前内容承诺与可达路径，并统一历史评分口径；它们直接决定用户能否相信、能否完成任务。
2. 统一跨页指标色、去掉音高涨跌的自动褒贬；这比换一套渐变、圆角能更直接降低读图负担。
3. 改善练习入口的任务说明和教程“查看方法/继续操作”的衔接，同时保留原生列表和已克制的 reader。
4. 再处理辅助功能步骤语义与待验证的大字号布局；后续用户允许运行时，按同设备、同状态检查布局和交互。当前不需要启动模拟器补流程。
