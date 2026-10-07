# Pitchee 全量视图设计与交互审查

日期：2026-10-06，Asia/Shanghai。对象：当前 iOS / SwiftUI 工作区，包括未提交改动。

**核心判断：Pitchee 把很多声学能力做成了界面，但用户仍要自己决定先看什么、这些数字意味着什么、接下来怎么练，以及当前操作究竟有没有结束。持续的理解负担、评价压力和状态不确定性叠加，最能解释“用起来难受”的感受。** 这是有源码依据的设计诊断，不是用户研究结论。

按照用户“先不要用模拟器，完整检查所有视图”的要求，最终审查采用源码、导航关系、状态模型与真实中文资源。先前运行准备已停止；本报告不使用模拟器画面作证据，也不以构建尝试代替视觉验收。没有修改应用源码或设计，只新增审查文档。

参考用户提供的 [ada-interaction-design Skill](/Users/dannyfeng/Downloads/ada-interaction-plugin/skills/ada-interaction-design/SKILL.md) 及其相关 reference。采用其中“第一焦点服务任务、信息顺序稳定、图形准确解释数据、状态和动作一致”的方法；没有把参考 App 的宣传效果或奖项当成评价依据，也没有实测 Flighty/Moonlitt/Lumy。

## 覆盖范围与证据边界

已完整覆盖 **31 个含界面声明的 Swift 文件、126 个 App 入口/视图/组件/修饰器/预览类型**，约 9,724 行；还核对相关状态模型、音频会话、指标展示模型与 49 篇知识库实际资源。完整声明清单及源码指纹见 [逐文件视图清单](/Users/dannyfeng/Documents/Pitchee/Docs/Design-Interaction-Review-2026-10-06/View-Inventory.md)。私有子组件、ViewBuilder 分支、sheet、alert、帮助、设置、空/失败/等待状态均纳入所属文件审查。

| 证据级别 | 本次能说明什么 |
| --- | --- |
| 代码确定 | 页面内容顺序、导航可达性、标题与数值的对应、状态条件、操作缺失、显式尺寸与缩放策略 |
| 设计解释 | 上述结构可能怎样增加注意切换、判断负担、被评判感或不确定性；没有代替真实用户测试 |
| 待渲染/运行 | 首屏实际可见范围、文字裁切、合成对比度、动效、触觉、VoiceOver 实际播报、录音硬件状态、响应耗时 |

P1/P2/P3 是本次整改优先级：P1 优先解决任务与状态可信度，P2 解决显著理解/恢复成本，P3 完善局部一致性。它们不是线上故障统计或 Apple 官方评分。

## 为什么整体不舒服

当前主路径的注意力顺序是：

**进入先看统计 → 练习先选工具 → 评分先看仪表 → 结果先看分数和倾向 → 下一步去读文章 → 文中部分练习没有入口。**

每一屏都有内容，但“我现在要完成的一件事”没有持续成为主角。视觉和语义又在跨页变化：同一个指标换颜色、同一条历史记录换评分目标、相似录音控件采用相反的离开行为。用户既要学声学知识，又要重新解释界面的规则。

### 1. P1：开始与练习的入口没有围绕当前任务组织

首页默认是趋势报表，先显示分析次数和打开天数；无数据时仍显示一组 0/—，最后才出现没有按钮的提示。[首页顺序](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:250)。

训练页把“评分、实时基频、实时频谱、Spectrum”四个同权重入口放在“实时检测”里；知识分类先列算法规则、分数区间，再到具体方法。用户必须先懂工具才知道选哪一个。[训练入口](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeHubView.swift:33)。

**决定：**首页首组回答“现在可以做什么”；初次使用给明确的第一次录音入口。训练保留工具列表，但优先展示一次可执行任务，工具名称附用途；区分实时频谱与声谱图。详情见 [App A1](/Users/dannyfeng/Documents/Pitchee/Docs/Design-Interaction-Review-2026-10-06/App-and-Settings.md)、[练习 PI-02](/Users/dannyfeng/Documents/Pitchee/Docs/Design-Interaction-Review-2026-10-06/Practice-and-Insights.md)。

### 2. P1：教程承诺的 A/B 练习没有接入当前产品

49 篇实际文章中有 11 篇提及“App 的 A/B”“当前 iOS 引导练习”等现有功能表述；当前 PracticeRoute 没有该路线，GuidedPracticeSessionView 只有定义，没有实例调用。[实际资源例子](/Users/dannyfeng/Documents/Pitchee/Resources/VoiceTrainingLibrary/voice-training-library.json:41)、[当前路由](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeHubView.swift:3)。

用户读完会去寻找不存在的入口，容易以为自己没有学会使用。**决定：**保留 A/B 就接通现有流程及教程上下文；暂不提供就修订“App 已有该功能”的文案。未接入的视图已检查，但它们的旧外观不用于解释当前可见界面。详见 [PI-01 与可达性表](/Users/dannyfeng/Documents/Pitchee/Docs/Design-Interaction-Review-2026-10-06/Practice-and-Insights.md)。

### 3. P1：录音和监听缺少一致、持续可见的状态约定

评分模型由主 Tab 容器持有；切到别的 Tab 后停止控件隐藏，却没有调用结束录音。监听工具则会在切 Tab/离页时停止并清空临时会话。[控制条可见条件](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:117)、[监听清空](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViewModel.swift:362)。

监听的“实时/暂停/回放”状态只写入 accessibilityValue，视觉文本始终是工具名。拖动、回退或中断会暂停，数字和图仍在，用户需要猜它们是不是实时值。回放时右侧按钮甚至被标成“暂停回放”，实际执行开始采集。[状态和动作](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorTabAccessory.swift:24)。

**决定：**正在录音时持续保留状态和停止入口；普通离页、暂停、结束三种行为明确分开。控制条直接显示“实时采集中 / 已暂停·查看某时刻 / 回放中”，图标、可见文字、读屏名称和动作从同一状态生成。代码路径已确定；真实麦克风行为本轮未测。详见 [M01–M04](/Users/dannyfeng/Documents/Pitchee/Docs/Design-Interaction-Review-2026-10-06/Monitoring-and-Scoring.md)。

### 4. P2：评分页的构图没有服务“自然朗读”

窄布局先放大号音高、时长、标尺，再放 220–360 pt 曲线，最后才是参考语料。[ScoringView.swift:24](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/ScoringView.swift:24)、[语料位置:139](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/ScoringView.swift:139)。同一频率被数字、尺和曲线反复表达，用户要读的内容优先级反而最低。

**决定：**评分页以语料和录音状态为主体，音高反馈收为紧凑辅助区；实时音高工具继续以仪表为主体。不是把每个组件都缩小，而是减少当前任务不需要的重复表达。实际首屏是否被推出须后续渲染确认。

### 5. P2：同一对象在跨页时改变解释，损害数据可信度

| 位置 | 已确认的不一致 | 修改方向 |
| --- | --- | --- |
| 历史列表 → 详情 | 列表按当前设置的声音目标算分，详情优先用录制时目标；改目标后同一记录可显示不同方向/分数 | 同一条记录沿导航保持同一口径；主动重评时明确标记 |
| 首页 → 指标详情 | 自然度由紫变青、音高由青变橙；综合分数字蓝、曲线紫、详情又用主题色 | 每个指标共用一份展示样式 |
| 音高趋势 | 所有下降均红色、上升均绿色，未考虑目标 | Hz 变化中性表达；接近目标才可表达好坏 |
| 男性向结果 → 导出 | 导出把 100−VFP 的数值仍标为“音色分（VFP）” | 目标、标题、数值与屏幕结果共用展示模型 |
| 没有独立底噪窗口的导出 | 最低语音分位估值被画成整段平直“环境底噪”曲线 | 标明估计参考线，或直接说明没有独立样本 |

证据：[历史口径](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:137)、[详情口径](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:195)、[指标颜色](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsData.swift:78)、[涨跌色](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:650)、[导出反向值](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:513)、[底噪曲线](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:1000)。这些无需依赖审美偏好即可确认。

### 6. P2：结果更擅长给评价，较少帮助人完成下一次练习

结果先放 78 pt 总分与声音倾向图，后放建议；建议操作主要是阅读文章和浏览知识库，没有带着本次建议再练一次的动作。倾向气泡的直径从 78 pt 起步再线性增加，0% 仍有明显面积，却在图注中被描述为占比，图形不能准确表达它承诺的比例。[结果顺序](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:157)、[气泡映射](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:807)。

评分解释又先展开完整公式，才解释本次命中的规则。建议打开文章后，也从完整背景开始，方法前通常有数百字符，部分超过千字，没有章节锚点。[说明页](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:478)、[文章阅读顺序](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/VoiceTrainingLibrary.swift:750)。

**决定：**先提供“本次观察 → 一项动作 → 再试一次”；完整分数、倾向、规则、公式保留在支持判断的层级。文章保留前提和完整内容，增加方法定位；从百科浏览和从具体建议进入，可以有不同的初始焦点。详见 [结果 A01–A03](/Users/dannyfeng/Documents/Pitchee/Docs/Design-Interaction-Review-2026-10-06/Analysis-and-Export.md)、[阅读 PI-06](/Users/dannyfeng/Documents/Pitchee/Docs/Design-Interaction-Review-2026-10-06/Practice-and-Insights.md)。

### 7. P2：很多默认态已完成，等待、降级、失败态仍缺少解释

| 界面 | 具体缺口 |
| --- | --- |
| 评分图表 | 数组非空但全是无声音高时，空图没有原因提示；未开始/准备/录音无声的读法不完整 |
| 实时音高降级 | 录音仍继续，却出现“无法开始录音”的模态标题，打断朗读 |
| 分析页 | 等待时隐藏返回，失败后没有就地重录动作；全局 Tab 仍可用，并非整个 App 锁死 |
| 导出 | isSaving 禁用列表、保存、关闭，却没有保存中指示；耗时未测 |
| 图标选择 | 失败只忽略回调，不解释；不支持时全部禁用仍显示“立即更新”说明 |
| 钢琴 | 音频准备失败仅写日志，但按键仍给亮起/触觉反馈；用户无法从界面判断为何没声音 |
| 本地对照自评 | 正在要求用户回答问题，父级标题却仍是“正在分析” |

**决定：**每个组件明确未开始、操作中、成功、失败和恢复方式；状态只改变相关区域，不依赖模态弹窗解释可恢复的图形降级。详见各分报告中的状态矩阵与文件位置。

### 8. P2/P3：视觉系统缺少统一规则，局部精修应排在任务和语义之后

- 引导的标题/正文、首页数值、钢琴频率大量用固定字号，Monitor/Scoring 已用 ScaledMetric；放大字号的策略跨页面不一致。中文引导标题直接使用负 tracking，也应单独调整。
- 首页音高读数缺 Hz，部分重要解释使用 caption2/tertiary；大数字的重要感强，时间与比较口径却不完整。
- 主题设置只预览色块，任意颜色直接用于文字与曲线，没有浅/深背景上的真实内容预览与可读变体。
- 钢琴用 24 个同等玻璃面网格；两列需要 12 行，邻音位置随列数变，蓝/粉/灰音区没有说明。应围绕参考音与相邻半音建立稳定空间关系。
- 实时音高前 10 秒会把已有数据不断铺满整图，使同一片段不断改变位置与形状；评分与声谱图已有固定窗口，时间读法应统一。
- 等宽数字没有固定整个数值区域，—、99.9、100.0 的切换仍可能移动 Hz；这是后续组件精修项。
- 图表读屏主要只有时间范围；文章有序步骤的序号被隐藏；钢琴只暴露音名和一次播放，未提供频率/持续/停止的对应操作。
- “关于”Tab 实际承载声音目标、主题、隐私等设置，入口应与用途一致。

以上分别有明确代码依据；实际对比度、文字裁切、动态位移大小和读屏效果未验证，不能据此声称所有用户都遇到相同问题。

## 全视图覆盖摘要

下表把全部 31 个界面文件按用户面对的区域汇总；所有类型和行号在[清单](/Users/dannyfeng/Documents/Pitchee/Docs/Design-Interaction-Review-2026-10-06/View-Inventory.md)及分报告中列出。

| 区域 | 已检查的页面与状态 | 结论 |
| --- | --- | --- |
| App 入口/主导航 | 存储失败、首次引导、四 Tab、导航与浮动控制条 | 存储失败说明可保留；默认任务焦点和录音可见性需改 |
| 引导/声音偏好 | 欢迎、偏好选择、进度、底部按钮、隐私承诺 | 两步流程和明确选择保留；字体策略和现行音频说明需校准 |
| 首页趋势 | 时间范围、次数/天数、综合分、自然度/音高、无数据 | 主次、单位、比较口径、色彩语义需改 |
| 历史/指标详情 | 历史列表、历史结果、单指标曲线/选择、空/损坏数据 | 列表结构保留；跨页评分目标需统一；大字号待验 |
| 活动日历 | 系统日历、时间范围、双类装饰、所选日及当天记录 | 原生日期操作和形状+文字状态保留；实际读屏待验 |
| 训练中心 | 工具入口、分类、知识库搜索及无结果 | 功能同权重、术语及功能可达性需改 |
| 声音评分 | 语料、读数、标尺、曲线、录音控制、无声/错误/分析 | 阅读任务主次与状态可见性优先处理 |
| 实时基频/频谱 | 读数、对数尺、Canvas、滑块、窗口菜单、帮助与错误 | 主画布方向可保留；状态和时间尺度需改 |
| Spectrum 声谱图 | 热图、幅度色标、频率/时间轴、游标、设置、帮助 | 数据图形有作用；身份命名、窗口反馈、读屏需统一 |
| 结果与公式 | 结果概览、倾向图、建议、声音详情、公式与规则、错误 | 增加可行动下一步，修正图形比例和解释顺序 |
| 导出 | 选择、分页缩略图、A4、各图表/指标、PNG/PDF、权限/保存结果 | 指标含义、估值标记、缺失数据、放大预览、保存反馈需改 |
| 知识库阅读 | 分类/筛选、列表、文章header、章节、公式、表格、步骤、分享 | 当前克制阅读排版应保留；方法定位和内容承诺需改 |
| 钢琴 | 网格、持续发声触摸、取消/滚动、声音准备、读屏 | 音阶空间、失败反馈、可访问动作需改；清理逻辑保留 |
| 设置/图标 | 声音偏好、隐私、主题、图标、版本、本地工具入口 | 系统 Form 保留；命名、主题预览、图标状态需补 |
| 本地诊断/自评 | 启用、统计、错误、清空、等待反馈、跳过 | 高级工具分组基本合理；自评标题与当前步骤不符 |
| 适配与共享组件 | AccessibleStack/Picker、折叠容器、按钮、玻璃、预览 | 保留系统能力与现有有效适配；统一在现用页面的使用策略 |
| 未接入代码 | 旧 RecordingView/图片导出链、GuidedPractice、PracticeTrends、旧文章行等 | 已完整审查；不将其外观误算作当前体验。A/B 文案与可达性仍是现状问题 |

## 建议改动顺序与设计方向

以 Skill 提炼的 Flighty“当前状态 → 下一动作 → 支持信息”作为主标尺；核心声学图形借鉴 Moonlitt 的“主体承担信息、控件沿边缘组织”原则。视觉性格定为**安静、明确、可行动**：克制颜色、稳定读法、每屏一个主要任务。设置和资料列表保持系统结构。

1. **先修可信度和行为约定。** 录音跨页状态、监听暂停/离页语义、历史评分口径、导出标题/估值、教程的不存在入口。
2. **再修任务焦点。** 首页的第一次行动、评分语料主导、结果的一项观察和下一步、从建议直达方法。
3. **统一视觉语义。** 同指标颜色、单位/日期/比较对象、展示与正文角色、字号重排、主题色可读变体。
4. **补完组件状态。** 无声、降级、等待、保存、换图标、声音不可用、反馈/退出。
5. **最后核对实际画面与细节。** 数字占位、轴刻度、材质、曲线过渡、触觉及辅助功能。当前依照用户要求不执行模拟器验收。

建议保留当前已经有效的部分：原生 NavigationStack/List/Form/Picker/Slider/日历；知识库的正文式排版；建议最多两条；缺失值不伪造成 0；保存失败仍保留结果；录音共享按钮的 44pt 区域；图表无声断线；静态网格与实时曲线分离。没有依据把问题一概归因于“系统控件不好看”“玻璃不够多”或“动画不够多”。

## 完整分报告

- [App、引导、首页、设置、钢琴与诊断](/Users/dannyfeng/Documents/Pitchee/Docs/Design-Interaction-Review-2026-10-06/App-and-Settings.md)：A1–A9，含已覆盖保留项。
- [监测、评分、声谱图及状态模型](/Users/dannyfeng/Documents/Pitchee/Docs/Design-Interaction-Review-2026-10-06/Monitoring-and-Scoring.md)：M01–M11，含全文件覆盖、关键状态矩阵与源码指纹。
- [分析结果、说明、导出及旧图片链](/Users/dannyfeng/Documents/Pitchee/Docs/Design-Interaction-Review-2026-10-06/Analysis-and-Export.md)：A01–A11，含全部子组件与可达性。
- [练习、知识库、历史、趋势详情与日历](/Users/dannyfeng/Documents/Pitchee/Docs/Design-Interaction-Review-2026-10-06/Practice-and-Insights.md)：PI-01–PI-07，含 49 篇实际资源与阅读器类型核对。
- [31 文件 / 126 类型的声明清单](/Users/dannyfeng/Documents/Pitchee/Docs/Design-Interaction-Review-2026-10-06/View-Inventory.md)：逐类型定位，用于检查覆盖和之后源码漂移。
