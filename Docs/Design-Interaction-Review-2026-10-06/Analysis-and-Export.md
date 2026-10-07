# Pitchee Analysis 视图完整代码审查

审查日期：2026-10-06。审查范围是当前工作区，包含未提交改动；没有启动模拟器、没有构建、没有修改应用源码。本文是代码、结构、状态与数据呈现审查；所有实际尺寸裁切、对比度、动画连续性、触感、响应耗时仍待后续渲染或运行验证。

依据：用户提供的 `/Users/dannyfeng/Downloads/ada-interaction-plugin/skills/ada-interaction-design/SKILL.md`，以及 `visual-system.md`、`component-craft.md`、`swiftui-craft.md`、`motion-craft.md`、`visual-review.md`。采用的判断顺序是任务与焦点、信息顺序、组件语义、状态恢复、最后才是材质细节。没有依据参考 App 的印象声称当前界面达标或不达标。

## 范围与可达性

完整逐段阅读以下 6 个文件，共 2,877 行；包括文件中所有嵌套视图、辅助组件和 Preview。为核对入口和文案，额外读取了当前 `ContentView`、`ScoringView`、`PracticeSuggestionsSection`、`InsightsDetailViews` 的相关入口，以及 `AnalysisViewModel`、`RecordingStatistics`、`VoiceScoring`、`VoicePreferences` 和中文字符串的相关部分。额外文件只用于依赖核对，不冒充完整覆盖。

| 文件 | 完整覆盖内容 | 当前可达性 |
| --- | --- | --- |
| [RecordingAnalysisView.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:1)，1–1059 行 | 分析中、等待研究反馈、结果、无结果/失败；结果主区、建议、文章/知识库 sheet；声音详情 sheet；评分说明、基础公式、本次规则、其他规则、FormulaBlock；倾向图、音高尺、玻璃修饰器；指标组件；所有 Preview | 当前可达。`ContentView:86` 进入分析；历史详情 `InsightsDetailViews:195` 复用结果视图 |
| [RecordingExportView.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:1)，1–1180 行 | 导出按钮与 sheet；选择列表和分组；图表/指标枚举；预览翻页与分页模型；A4 画布、头尾、指标行、空状态；曲线、图例、倾向图；相册权限、保存成功/失败、PDF 文件导出；所有 Preview | 当前可达。新结果和历史结果均有导出按钮；历史入口固定传入 `volumeStatistics: nil` |
| [RecordingView.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingView.swift:1)，1–148 行 | 普通/折叠布局、图表/语料面板、分析导航、录音错误、所有 Preview | 当前没有生产入口。全库引用只发现本文件 Preview；当前评分页已改用 `ScoringView` |
| [RecordingTabAccessory.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingTabAccessory.swift:1)，1–189 行 | 旧包装器；iOS 版本分支；共享录音 accessory；默认/准备/录音/分析文案；44pt 图标按钮；按压样式；Preview | `RecordingTabAccessory` 旧包装器仅旧 Preview 使用；`TabBarAccessory`、`RecordingAccessoryContent`、`RecordingAccessoryButton` 是当前共享组件，分别被主导航和监测页使用 |
| [PitchImageExportButton.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/PitchImageExportButton.swift:1)，1–142 行 | 即时 PNG 渲染、预览 sheet、保存文件/分享、透明度替代、保存失败、FileDocument、Preview | 当前未发现生产调用；文件内只有 Preview。不能把这里的分享能力算作当前报告导出的已有入口 |
| [LivePitchChartView.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/LivePitchChartView.swift:1)，1–159 行 | 实时读数可访问性；Canvas 音高绘制、坐标、断线；完整时间轴图片布局；Preview | `LivePitchChartView` 仅旧 RecordingView 使用；`PitchPlot`/`PitchTimelineImage` 被上述旧图片导出链使用。当前 ScoringView 使用的是 `MonitorPitchPlot`，不是这里的 `PitchPlot` |

状态分类：**确定代码**表示结构、条件或数据映射能直接从实现确认；**待渲染**表示代码已指向风险，但不声称已经看到问题。P1 表示核心任务被阻断或严重误导且需立即处理；P2 表示明显妨碍理解、信任或完成任务；P3 表示局部一致性与可发现性。本文没有依据静态代码强行报出 P1。

## 当前可达的实质发现

### A01 · P2 · 结果主要在评价用户，练习的下一步没有同等清晰的动作

**感受与原因：**结果先展示大分数、进度条与泛化的分数区间文案，再展示声音倾向图；建议在这组之后。建议行打开文章，另一个操作是浏览整个知识库。用户看完结果后，缺少与这次建议绑定的“再练一次”动作，需要自行返回评分页并把文章里的建议记在脑中。这里不是建议条数过多：现有建议只显示两条，这一点是有效的。

**证据：**[结果内容顺序](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:157)、[建议与浏览知识库操作](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:234)、[78pt 总分与进度条](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:310)、[建议只打开文章](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeSuggestionsSection.swift:14)。当前 `RecordingResultView` 没有 retake/action 回调。

**具体改法：**首组给出本次最值得关注的一项观察和可执行的一项动作，配“按这条建议再录一次”。分数仍可保留；倾向参考或完整图表可以下沉。文章入口表达为“了解原因/练习方法”。历史结果上的下一步可用“用这个目标开始练习”，避免按钮含义依赖返回栈。

**证据级别：**内容顺序和动作缺失为确定代码；“被评判”“下一步悬空”是设计解释，尚无用户测试。

### A02 · P2 · 倾向图的圆形大小并不表达比例，且音高信息缺少直接读数

**感受与原因：**同一视觉组放一条 50–350Hz 竖尺和两颗女性/男性百分比玻璃球。圆直径为 `78 + (maximumDiameter - 78) × percentage/100`，所以 0% 仍是直径78的球；非零基础加上线性直径也不对应面积比例。导出图注却明确说“圆形大小表示声音倾向参考占比”。读者无法依靠图形准确扫读差异，仍必须回到百分比数字。左侧音高只显示上下界和“平均”标记，没有在标记旁给实际 Hz；精确信息需要再开声音详情。

**证据：**[两类图形并列](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:763)、[直径映射](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:807)、[音高尺的平均标记](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:920)、[导出图注位置](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:1133)。图注中文已核对 `export.chart.result.caption`。

**具体改法：**倾向改为清楚的互补比例条或直接并排数值；若保留气泡，则不要暗示它是比例图，并明确其装饰角色。音高单列实际读数与范围，或在尺上标出平均值和核心范围。先选择一套主要读法，再决定是否保留材质。

**证据级别：**映射与图注为确定代码；具体显著性、材质合成对比度待渲染。

### A03 · P2 · 点开“为什么得这个分”，先要跨过完整公式，才看到与自己有关的原因

**感受与原因：**评分说明顺序是介绍→基础公式→本次命中规则→其他规则。女性/未确定分支一次展开8项数学表达；男性分支5项，后面又在当前规则中重复核心公式。表达式里没有把本次 F0、Naturalness、VFP 代入，用户仍需自行对应详情中的数字。技术透明度存在，但它被放在解释当前结果之前。

**证据：**[说明页顺序](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:478)、[展开的基础公式](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:521)、[当前规则在后](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:546)、[FormulaBlock](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:625)。

**具体改法：**先给一句本次原因、相关读数及其影响，再放“计算细节”DisclosureGroup；基础定义与完整公式留在其中。当前规则可以显示一次简短代入示例；“其他规则”继续默认收起。保留数学透明度，同时降低第一次理解门槛。

**证据级别：**确定代码。最长男性公式在小屏/大字号下是否溢出尚未渲染；不能仅凭 LaTeX API 推断已经截断。

### A04 · P2 · 关键说明入口只按图标/文字的固有大小命中

**感受与原因：**总分旁问号是 `.title3` 图标的 plain NavigationLink，没有44pt最小区域；“声音详情”也是 plain Button，只包一行 subheadline 与小箭头。它们分别承担解释总分和进入所有指标的任务，但实现没有像共享录音按钮那样保证命中区。

**证据：**[问号入口](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:299)、[声音详情入口](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:182)、对照[共享按钮明确44pt](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingTabAccessory.swift:160)。

**具体改法：**保持图标视觉大小，给问号44×44pt占位和命中区域；“声音详情”至少44pt高，或把标题行明确做成整行披露入口。避免与邻近标题命中区域重叠。

**证据级别：**缺少明确最小命中区为确定代码；平台实际布局尺寸与命中边界待渲染/操作核对。

### A05 · P2 · 男性化报告把反向指标标成 VFP，导出语义与结果详情不一致

**感受与原因：**导出 `.standardScore` 的标题始终是 `common.metric.standardScore.title`，中文是“音色分（VFP）”；但当 `scoreProfile == "masculinization"` 时数值为 `100 - VFP`。同一录音在结果详情用的是目标相关标题“男性化倾向”，导出后却换成 VFP 标签。报告标题只有“声音分析报告/导出内容”，结果图也不传入目标偏好，缺少帮助读者解释该数值的上下文。

**证据：**[固定导出标题](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:438)、[反向数值](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:513)、[结果详情使用目标相关标题](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:269)、[报告标题](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:751)、[导出倾向图不传目标](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:1127)。字符串已直接核对。

**具体改法：**导出使用与屏幕结果相同的目标/指标展示模型，让标题、数值、说明来自同一份语义；报告注明分析目标及评分版本。至少立即将反向值标为“男性化倾向”，不再称为 VFP。

**证据级别：**确定代码，不依赖视觉渲染。这是内容正确性问题。

### A06 · P2 · 没有独立环境采样时，报告仍画出一条“环境底噪”曲线

**感受与原因：**`RecordingVolumeAnalyzer` 在没有非语音窗口时，用语音最低5%分位估算 `environmentDBFS`。导出背景曲线遇到没有独立背景窗口，会把这个估值复制到每个时间点；相应标题/图注仍说是“未检测到语音时的环境底噪”。详情页也以环境底噪呈现该值，并据此显示高于底噪的增量。用户无法区分真实采样与推断，可能把平直线当成整段稳定的背景测量。

**证据：**[底噪估计的回退](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingStatistics.swift:169)、[导出复制估值为曲线](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:1000)、[详情展示估值与相对增量](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:382)、[增量计算](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:442)。模型已有[独立测量属性](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingStatistics.swift:75)。

**具体改法：**没有独立背景窗口时显示“未取得独立底噪样本”，不画伪装成测量的时间曲线；如确需估值，将其明确写成“估计参考线”并用虚线。音量相对增量同时标注其参考来源，不能以纯视觉平滑掩盖数据缺口。

**证据级别：**确定代码与文案；不涉及算法该不该估算，只涉及估算值如何呈现。

### A07 · P2 · 报告预览在手机上缩得很小，却占据大量空间且没有放大入口

**感受与原因：**导出页先给一整块A4比例预览，再给格式和选择列表。A4内部指标只有9.5pt，单位8.5pt，曲线坐标7.5pt；预览再把595pt宽画布等比缩到容器宽，因而这些内容进一步变小。没有点按放大、缩放或全文预览入口。用户为了选择导出内容，需要核对一幅只能辨认构图的缩略图。

**证据：**[预览在列表首部](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:49)、[A4比例与翻页](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:163)、[整页缩放](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:677)、[指标与单位字号](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:857)、[图表坐标字号](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:938)。

**具体改法：**缩略图只用于版式概览，提供明确“放大预览”进入可以阅读的全屏查看器；导出配置上方保留紧凑的页数/内容摘要。页面内可读的关键选择反馈不应依赖缩略图里的文字。

**证据级别：**缩放链、固定字号、无放大操作为确定代码；实际阅读难度待同尺寸渲染。固定字号在导出文件画布内本身合理，问题是把画布继续缩小当作唯一预览。

### A08 · P2 · 保存时页面被锁住，但没有“正在保存”的可见反馈

**感受与原因：**`isSaving` 使整个列表禁用、保存按钮禁用、交互关闭被阻止，但按钮的内容不变，也没有进度指示器或保存中文案。生成图片/PDF都在MainActor逐页同步渲染。即使任务最终成功，等待时用户会看到操作失效却不知道原因；具体停顿时长尚无运行证据。

**证据：**[禁用列表和保存按钮](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:90)、[阻止关闭](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:128)、[保存状态与任务](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:193)、[逐页图片渲染](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:234)、[逐页PDF渲染](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:259)。

**具体改法：**保存按钮保留占位并显示 spinner/“正在生成报告”，明确相册保存还是准备文件。必要时逐页报告真实进度；未知阶段不用假百分比。异步部分做好状态反馈，渲染安排再按测量优化；若允许取消，保证取消不会产生错误成功提示。

**证据级别：**无反馈和禁用状态为确定代码；卡顿与持续时间待运行验证，不宣称存在性能回归。

### A09 · P2 · 从历史导出时，默认选择一批根本没有保存的数据

**感受与原因：**历史详情固定传入 `volumeStatistics: nil`；导出却无条件全选4种图表和18个指标。选项也不按可用性调整。音量数据变为“—”，音量/背景曲线图例仍被选中但没有曲线。历史结果的声音详情同样出现整组不可用音量指标，并用一般dBFS说明解释它们，缺少“此记录未保留音量统计”的原因。缺失值没有伪造成0，这很好；但没有解释缺失来源。

**证据：**[历史调用传nil](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift:195)、[默认全部选择](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:37)、[不检查可用性的选项列表](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:66)、[缺数据仍绘制空曲线组](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift:987)、[声音详情总是展示音量组](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:351)。

**具体改法：**按记录的数据可用性设默认勾选；缺数据的选项显示原因并禁用或收进不可用组。详情用一个清楚的缺失说明代替四张空指标卡。保留主动查看完整原始字段的能力，但不要让常规导出默认包含空内容。

**证据级别：**确定代码；空组的实际首屏占比待渲染。

### A10 · P3 · 男性化说明存在一个展开后为空的“其他评分规则”入口

**感受与原因：**男性规则文档只有 `continuous` 一条；其他规则组无条件出现，内容把当前规则过滤后为空。用户操作这个披露组件不会获得新的信息，像是展开失效。

**证据：**[无条件 DisclosureGroup](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:585)、[男性规则只有一项](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:728)。

**具体改法：**先计算剩余规则，非空才出现“其他规则”；空集合不需要额外空状态。

**证据级别：**确定代码。

### A11 · P3 · 分析等待与失败的恢复动作不够直接

**感受与原因：**分析中只显示不定进度和说明，同时隐藏返回按钮；页面没有显式取消。失败后显示系统无结果视图，文案要求“返回录制”，但没有原地重录操作。底部Tab仍在，不能把它形容为整个App被锁死；问题是当前任务缺少一个明确结束/恢复途径。

**证据：**[分析状态分支和无结果](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:20)、[分析时隐藏返回](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:42)、[仅不定进度](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:69)。`analysis.emptyState.noResult.description` 中文已核对。

**具体改法：**失败状态直接提供“重新录音”；若支持分析取消，提供有明确语义的关闭/取消，并让模型按同一任务身份取消。若产品有理由要求这次分析完成，至少说明可以切换页面并保留进度。不要用虚构百分比代替不定进度。

**证据级别：**确定代码的动作缺失；等待是否足够长到影响体验待运行验证。研究反馈本体在 Diagnostics 文件，本文只覆盖容器分支，不重复报告其内部交互。

## 逐文件可保留部分与边界

### RecordingAnalysisView.swift

- 已把11项详细指标放进声音详情 sheet，没有把全部工程数据直接铺在结果页；这比一屏塞满数值更合理。
- 声音详情有标题、完成按钮、medium/large detent、滚动区；指标用 adaptive 网格，数值/单位有 `ViewThatFits` 横排转纵排。它们是有效的布局基础，不能因未运行就断言大字号完全失效。
- 建议数量限定为2条；缺失音高、音量使用“—”，没有伪造0。保存历史失败保留分析结果，并单独提示失败，不丢失当前可用内容。
- 结果分数用等宽数字；倾向图整体提供 VoiceOver 文本，内部装饰隐藏；音高范围/均值动画读取 Reduce Motion。没有高频逐帧翻动总分的业务路径。
- 当前其他规则默认收起是正确方向。公式页采用系统导航、正文可换行；应调整顺序和必要性，而不是删除全部技术解释。
- 固定78pt分数、25pt气泡值、固定40pt音高尺、固定180pt轨道不代表完成Dynamic Type验证；小屏大字、长本地化、Reduce Transparency和合成背景对比度仍需单独看画面。
- 除A11外，没有因某个状态缺少额外按钮就批量报错：分析中的不定进度真实反映未知进度，静态代码不能证明它等待过久。

### RecordingExportView.swift

- 使用系统 `List(selection:)`、`Picker`、fileExporter 和权限接口；选择没有另造脆弱手势。报告内容可取消选项，选择全空时禁用保存且预览有空状态。
- 预览与导出使用同一 `ExportReportPage`，降低预览与输出不一致的机会；自动分页、页码、翻页index收敛处理均存在。
- 固定A4、浅色模式、中等字号是文档画布的合理约束，不应照搬App Dynamic Type要求来判错；实际文档可读性需按最终输出尺寸检查。
- 曲线过滤非有限值、缺失窗口主动断线，图注说明断线含义；输出指标过滤nil/非有限值。这些有助于信任，应保留。
- 相册拒绝、图片生成失败、保存失败、PDF失败均有具体消息；相册成功仅在保存完成后出现，没有提前假成功。
- 尚未验证分页估算对所有语言/长指标值是否准确；不声称`estimatedBodyHeight`存在确定裁切。报告内9.5pt标签、8.5pt单位同排且单行，长语言/范围值应列入渲染样本。
- 预览只用页码label，没有给Canvas曲线提供摘要；三条线和图例使用相同线形、颜色分类。VoiceOver对图形内容的可读性、灰度/色觉区分属于后续重点，不以未实测宣称完全不可用。
- sheet只有系统拖动指示器，没有显式关闭工具栏项；这在iPhone有原生下拉途径，故没有独立报成阻断问题。可在后续统一“完成/关闭”语言。

### RecordingView.swift（旧链/Preview）

- 已完整检查所有布局和错误分支。语料使用语义body、可增长行高，滚动容器/内容最大宽度明确；错误提示不会覆盖已打开的结果。这些可以作为旧实现的优点。
- 正常布局也是图表先于语料，但当前入口已经替换为ScoringView；不把旧布局当作现在用户看到的证据。
- 不建议为这份旧视图进行视觉重做；应先明确它是保留参考、未来入口还是待删除旧代码。审查期不修改它。

### RecordingTabAccessory.swift

- 当前共享按钮明确44×44pt命中区；准备中spinner保留图标尺寸并禁用，状态文字没有消失；按压opacity/scale局限在按钮，Reduce Motion时取消缩放；无全页动画。
- 图标有a11y label、输入别名、停止动作提示，相关文字组合；辅助功能大字号隐藏辅助说明，但主状态仍保留。计时/实时数据没有在此逐帧驱动交互动画。
- iOS26.1/26.0使用系统tab accessory，旧系统使用safeAreaInset；主体目标是操作始终可达，应保留。
- `needsAnalysisScreen`分支的图标/文案说“查看分析进度”，但当前主导航只在`.scoring`时展示该accessory，分析会推入`.analysis`使其隐藏；`scoringAction`本身也不导航。未把这一理论时隙当作稳定现用缺陷，需要运行才能确认可见窗口。
- tactile强度、按住移出取消、语音控制命中、26.0 accessory占位、不同系统材质透明度均未验证。代码有sensoryFeedback并不等于触感良好。

### PitchImageExportButton.swift（旧链/Preview）

- 已检查生成失败、sheet、保存/分享、系统fileExporter、保存失败与FileDocument。底部用`AccessibleStack`，对Reduce Transparency给实色替代，有显式完成按钮，保留图片快照而不是刷新数据改变已打开预览。这些设计有效。
- 导出入口同步ImageRenderer且没有等待状态，长时间轴可能等待；图片按宽适配且无放大。这与当前报告有类似风险，但本链未发现生产调用，故不计入当前问题优先级。
- 文件存在不意味着当前App提供“分享整个报告”；当前可达报告页只有保存路径，不能把旧ShareLink当作功能验证。

### LivePitchChartView.swift（旧链/Preview）

- 已检查等待/未录音的可访问说明、0.6秒陈旧读数过滤、Canvas映射、时间标签、缺失断线、图片分页行布局。
- 图表标签使用ScaledMetric，断线与裁剪明确；完整时间轴图片包含每一行，避免只截当前可见窗口。独立文档强制light/medium合理。
- Canvas把音高夹在75–600Hz边界，边界以外没有溢出标记；画布没有给眼睛看的“尚未开始/暂无可靠音高”文案，只有a11y value。应作为旧组件再启用时的核对项，不归因到当前实时工具。
- 固定210/150pt高度配可缩放坐标标签，大字号时可用绘图区会缩小；实际碰撞待渲染。当前ScoringView使用另一份MonitorPitchPlot，本报告没有据此推断当前图表边界或性能。

## 状态检查完成情况

| 状态/场景 | 已从代码确认 | 未做的验证 |
| --- | --- | --- |
| 分析正常→结果 | 状态分支、结果顺序、导出入口、指标/建议 | 实际导航连续性、停留时长 |
| 分析中/研究反馈 | 不定进度、隐藏返回、反馈容器切换 | 取消策略的实际体验；反馈本体由其他范围审查 |
| 无结果/分析失败/历史保存失败 | 错误文案、保留有效结果、恢复入口缺口 | 实际错误复现与焦点 |
| 声音详情有/无音量 | 网格、缺失值、单位、sheet完成按钮 | 大字号、最长范围、本地化布局 |
| 分数说明女性/男性/未确定 | 基础公式顺序、当前规则、其他规则；男性空披露 | LaTeX渲染、溢出、VoiceOver数学表达 |
| 导出默认/取消选择/全空 | 22项默认勾选、分页、禁用保存、空预览 | 页码动画、滑页/选择同时变化 |
| 导出历史缺少音量 | nil链路、空曲线/占位数据仍被选中 | 最终页面观感 |
| 导出相册拒绝/生成失败/保存失败/成功 | 分支及结果反馈真实时序 | 权限与系统保存UI操作 |
| 导出多页等待 | 禁用/阻止关闭、无等待指示、逐页渲染 | 响应时间、UI卡顿、最终文件可读性 |
| 录音按钮准备/录音/空闲 | 稳定44pt、禁用、文案、局部按压、Reduce Motion代码 | 连续按压、移出取消、真机触觉 |
| 主题/大字/减少动态/降低透明度 | 有实现的替代与未覆盖的固定尺寸已记录 | 没有渲染或运行，因此没有填写“通过” |

## 建议处理顺序

第一批先处理语义正确性（A05男性导出标签、A06底噪估值、A09历史缺失内容），同时建立“结果→一项练习→再录”动作（A01）。第二批让说明页先解释本次结果（A03），把报告预览和保存状态变得可理解（A07/A08）。最后修局部组件（A02图形读法、A04命中区、A10空披露、A11恢复动作）。无需先对所有卡片换材质、加动画或调整圆角。

全文仅交付审查证据与具体修法；没有应用修改、构建结果、截图或交互验收结论。
