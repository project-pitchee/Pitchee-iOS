# Pitchee 设计审查分报告：监测工具、声音评分与声谱图

审查日期：2026-10-06。范围为 `PitcheeApp/Monitoring/` 的全部 13 个 Swift 文件，以及 `Practice/ScoringView.swift`、`Practice/PracticeSpectrumView.swift`，共 15 个文件。为核实可达入口、录音生命周期和共用控制条，另追踪了 `ContentView`、`PracticeHubView`、`AnalysisViewModel`、`PitchTimeline`、`RecordingTabAccessory`、`AudioSessionCoordinator`、`AudioSessionController`、`LivePitchAudioCapture` 和实际中文本地化。

按用户要求，仅阅读当前代码；没有使用模拟器、没有构建、没有录制麦克风、没有修改应用。报告中的“代码确定”指状态分支、内容顺序、数据映射和调用关系可以从源码确认；不代表已验证设备上的画面、SwiftUI 转场、VoiceOver 实际朗读、触觉或性能。涉及首屏裁切、字号观感、动画手感的判断单列为待渲染风险。工作区存在正在进行的其他修改，本文已按本轮最新源码重查行号；`MonitorViews.swift` 当前为 399 行，声谱图已独立到 `PracticeSpectrumView`，不再把之前的内嵌频谱显示选择器当作现状。

参考标准是用户提供的 [ada-interaction-design/SKILL.md](/Users/dannyfeng/Downloads/ada-interaction-plugin/skills/ada-interaction-design/SKILL.md)，以及其 [component-craft.md](/Users/dannyfeng/Downloads/ada-interaction-plugin/skills/ada-interaction-design/references/component-craft.md)、[motion-craft.md](/Users/dannyfeng/Downloads/ada-interaction-plugin/skills/ada-interaction-design/references/motion-craft.md)、[swiftui-craft.md](/Users/dannyfeng/Downloads/ada-interaction-plugin/skills/ada-interaction-design/references/swiftui-craft.md)。这些文件提供审查方法，不被视为用户要求实施重设计、启动模拟器或修改应用的授权。

## 结论与建议优先级

此区域最突出的不适来源是：状态和操作后果不够可见；同样的录音外观跨页面却有相反的会话行为；评分时仪表占据焦点，朗读材料退到后面；图表还缺少稳定读法和完整的替代阅读方式。源码已经有系统按钮、原生 Slider、留白布局、稳定数据订阅和部分可访问性处理，不宜把结论简化成“缺动画”或“都要加卡片”。

| 编号 | 优先级 | 发现 | 证据性质 |
| --- | --- | --- | --- |
| M01 | P1 | 评分录音切走 Tab 后，操作条隐藏而录音没有收尾 | 调用链确定，设备音频效果未实测 |
| M02 | P1 | 监测的实时、暂停、回放状态只对读屏暴露，视觉上不可见 | 代码确定 |
| M03 | P2 | 回放时右侧按钮名称“暂停回放”与实际“开始采集”相反 | 代码确定 |
| M04 | P2 | 普通返回或切 Tab 立即清空临时音频，后果只藏在帮助 | 代码确定 |
| M05 | P2 | 评分页把朗读材料排在多层仪表之后，任务焦点错位 | 顺序和尺寸确定，首屏遮挡程度待渲染 |
| M06 | P2 | 音高监测在短录音/接近起点时重新拉伸整个时间轴 | 数据映射确定，动效不适程度未实测 |
| M07 | P2 | 图表读屏只有时间范围，缺少音高/频谱内容 | 代码确定，读屏体验未实测 |
| M08 | P2 | 可恢复的实时音高故障用“无法开始录音”模态弹窗打断朗读 | 状态及文案确定，错误触发未实测 |
| M09 | P2 | 评分图表只区分“数组空/非空”，没有把无声与准备中的状态说清楚 | 代码确定 |
| M10 | P3 | 声谱图的工具名称和窗口设置反馈与相邻工具不一致 | 代码确定 |
| M11 | P3 | 高频读数虽使用等宽数字，单位仍随位数变化移动 | 布局结构确定，实际幅度待渲染 |

P1 优先修复会话控制与状态信任问题；P2 随核心流程整理；P3 是局部一致性与细节打磨。没有仅凭源码给帧率、卡顿、触觉质量或视觉品质打分。

## 实质发现

### M01 · P1：切换 Tab 隐藏了录音控制，却没有结束评分录音

**位置。** [ContentView.swift:44](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:44) 在 `MainTabView` 的 `@State` 中持有 `recordingModel`。[ContentView.swift:117](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:117) 以 `scoringPageVisible || activeMonitorModel != nil` 决定 accessory 是否显示；[ContentView.swift:132](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:132) 要求当前 Tab 必须为训练且路径末尾为评分。[ContentView.swift:125](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:125) 的 Tab 切换只执行 `monitorAccessoryState.leavePractice()`，没有处理评分录音。

**核实过的收尾路径。** [ScoringView.swift:49](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/ScoringView.swift:49) 只有进入和数据订阅逻辑，没有 `onDisappear`/场景状态处理。[AnalysisViewModel.swift:135](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/AnalysisViewModel.swift:135) 的 `interruptCapture()` 全仓只有定义，没有调用；[AnalysisViewModel.swift:490](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/AnalysisViewModel.swift:490) 的时钟只检查 `state == .recording`。音频对象保存在该存活模型中。`AudioSessionCoordinator` 是租约管理器，不是页面生命周期管理器；[AudioSessionCoordinator.swift:32](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Audio/AudioSessionCoordinator.swift:32) 在已有 `.recording` 租约时拒绝其他音频，不会自动停录。[AudioSessionController.swift:25](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Audio/AudioSessionController.swift:25) 只代理激活与释放。[LivePitchAudioCapture.swift:105](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Audio/LivePitchAudioCapture.swift:105) 安装 tap 并启动 engine，停止依赖显式 `finish/cancel`。

**影响。** 用户离开页面后看不到“正在录音”和停止入口，但应用没有结束该录音的代码路径。用户无法判断页面切换是否等于停止。之后使用其他音频工具还可能遇到已有录音占用会话的错误。

**具体修法。** 首选在任何 Tab 保留活跃录音 accessory，显示录音状态、时长和停止，并可回到评分页。若产品选择离开即结束，必须在路由切换时明确完成录音、保留内容并解释结果。不能仅隐藏控制条。

**待验证动作。** 训练 → 评分 → 开始录音 → 点击趋势 Tab，保持应用在前台且不启动其他音频 → 检查控制条/麦克风状态 → 回训练看时长。代码能证明“隐藏控件且未调用停录”；实际麦克风持续工作尚未设备验证。

### M02 · P1：监测状态缺少视觉表达，暂停和历史值容易被误认为实时值

**位置。** [MonitorTabAccessory.swift:24](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorTabAccessory.swift:24) 左侧只有工具图标和名称；第 39 行把 `statusKey` 放进 `.accessibilityValue`，没有显示状态文字。状态本身已经完整存在于 [MonitorViewModel.swift:53](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViewModel.swift:53)。[MonitorViews.swift:248](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViews.swift:248)、[PracticeSpectrumView.swift:168](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeSpectrumView.swift:168) 的拖动会暂停；[MonitorViewModel.swift:226](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViewModel.swift:226) 的回退也会暂停；耳机/音频中断和场景 inactive 同样暂停，见第 352、468 行。

**影响。** 用户只想回看曲线、拖了一次或从控制中心回来，屏幕仍有大数字、标尺和曲线，却没有“已暂停”的可见解释。此时继续发声无变化，看起来像应用失灵。红色圆形图标从停止变回录音，也不足以解释“恢复同一会话”与“重新开始”的区别。

**具体修法。** 保持控制条外部占位，显示“实时采集中”“已暂停 · 查看 00:12”“回放中”之一；主操作用“暂停采集/继续采集”。暂停时把大数字标为“所选时刻”，恢复实时后改回“当前”。状态用文字和图标共同表达，不只变颜色。

**待验证动作。** 正常采集 → 拖动并松手 → 发声；正常采集 → 外部音频中断 → 返回；回放完成 → 继续发声。逐个检查状态、读数语义和恢复入口是否一致。

### M03 · P2：回放状态下主按钮的可访问名称与动作相反

**位置。** [MonitorTabAccessory.swift:119](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorTabAccessory.swift:119) 的 `.replaying` 返回 `monitor.action.pauseReplay`（中文“暂停回放”）；但第 45–52 行实际按钮在所有非 `.live` 状态下执行 `model.startOrResume()`。此方法先停旧音频，然后进入采集准备，见 [MonitorViewModel.swift:100](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViewModel.swift:100)。真正的暂停回放已由左侧播放按钮提供，见 accessory 第 96 行。

**影响。** VoiceOver/语音控制用户会发现两个“暂停回放”入口，其中一个实际上重新打开麦克风。这是明确的动作语义错误，不只是无障碍文案不够精炼。

**具体修法。** 右侧在回放状态下命名为“继续实时监测”，可见文案同步；或让它真的暂停回放，但必须避免与左侧冗余且重新定义主操作。用统一的 action model 派生图标、标题、accessibilityLabel 和执行闭包，避免四处分别 switch。

### M04 · P2：普通导航会销毁监测会话，用户必须读帮助才能提前知道

**位置。** [MonitorViews.swift:100](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViews.swift:100) 与 [PracticeSpectrumView.swift:56](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeSpectrumView.swift:56) 离页时执行 `stopForLeaving()`；[MonitorAccessoryState.swift:22](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorAccessoryState.swift:22) 切离训练同样执行。[MonitorViewModel.swift:362](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViewModel.swift:362) 清空 timeline、游标、回放范围、分析器与错误，并恢复 idle。“仅保留最近 60 秒。离开监测页后清除，不保存为录音”只存在于帮助项 [MonitorViews.swift:323](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViews.swift:323) 和 [PracticeSpectrumView.swift:221](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeSpectrumView.swift:221)。

**影响。** “去趋势/钢琴看一眼再回来”会丢失刚才可回放的数据。与 M01 的评分录音离页持续相反，外观相似的控件没有一致的会话约定。

**具体修法。** 普通离页暂停并保留本次内存会话，提供明确的“结束本次/清空”动作。若暂存限制决定不能保留，需在主界面显式说明离开后果，并把结束与切 Tab 区分。不要因为这是“临时音频”就让普通导航承担清空动作。

### M05 · P2：声音评分以仪表为首要任务，朗读材料处于过低的位置

**位置。** 手机窄布局顺序在 [ScoringView.swift:24](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/ScoringView.swift:24)：先 `ScoringReadout`，再 `ScoringInstrument`。前者又包含大号频率、三行时长和 64pt 标尺，见第 85–106 行；后者先放 220–360pt 曲线，再放参考语料与朗读说明，见第 139–158 行。当前明确任务文案是“自然朗读参考语料”。

**影响。** 用户要读的内容排在三个重复音高表达和一个时钟之后。读材料可能需要滚动，一旦滚动又看不到关键录音状态。对“自然朗读”的任务，这种顺序会引导用户追逐实时数值而非完成语料，制造不必要的注意切换。

**具体修法。** 评分页把语料作为主对象，顶部只保留小型录音状态/时长；音高反馈收为一条简洁曲线或可展开辅助区。实时音高工具可继续把仪表作为主对象，评分不必照搬它的构图。减少重复表达比缩小每个组件更有效。

**证据边界。** 内容先后与最小高度是代码确定；尚未渲染，不能宣称某设备首屏必然完全看不到语料，或存在已验证裁切。需在正常中文、最长本地化和大字号下验证语料及主操作的同时可见性。

### M06 · P2：音高监测的时间尺度在短会话里不断变化，和评分/声谱图不一致

**位置。** [MonitorTimeline.swift:160](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorTimeline.swift:160) 返回 `max(available.lowerBound, cursor - duration)...cursor`。当只录到 1 秒时返回 0…1，2 秒时变 0…2。[MonitorPresentation.swift:57](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorPresentation.swift:57) 把此范围传给音高图；[MonitorCharts.swift:192](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorCharts.swift:192) 将它归一化到整个绘图区。因此同一 0.5 秒样本会在 1 秒时位于中央，在 2 秒时移到四分之一处，直到满 10 秒才稳定。拖到最早样本附近也会重新缩放。

评分页的 [PitchTimeline.swift:103](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/PitchTimeline.swift:103) 已用 `max(10, cursor)` 保持 10 秒范围；声谱图 [MonitorViewModel.swift:80](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViewModel.swift:80) 同样补足固定窗口。

**影响。** “10 秒窗口”在刚开始时并不是 10 秒的画面。同一条声音既因新数据推进，又因坐标尺度变化而移动；不同实时工具形成不同时间读法。用户很难凭形状判断节奏变化来自声音还是图表。

**具体修法。** 绘图窗口与可回放音频范围分别建模。未满窗口时保留空白，样本按固定时间比例填入；靠近起点拖动时保持绘图区长度，游标在其中移动。沿用评分/声谱图已有固定窗口方向，但需明确回放选择仍只包含实际音频。

**证据边界。** 映射变化可以从公式确定；没有录屏，不能把它描述成已实测“掉帧”或“卡顿”。

### M07 · P2：图表的可访问内容被压缩为时间范围，丢失了图形本身提供的信息

**位置。** [MonitorViews.swift:207](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViews.swift:207) 统一忽略 Canvas 子内容，只提供“图名＋开始/结束/当前位置”。这包括横轴实际为 Hz、纵轴为 dBFS 的 `MonitorSpectrumPlot`，其坐标定义见 [MonitorCharts.swift:15](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorCharts.swift:15)。[ScoringView.swift:172](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/ScoringView.swift:172) 与 [PracticeSpectrumView.swift:143](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeSpectrumView.swift:143) 使用相同简化方式。

**影响。** 可见用户能读到音高起伏、停顿、多个频率峰及声谱图中的谐波；读屏用户只得到时间范围和主读数。音高当前值与范围无法替代时间结构；频谱更被赋予与其坐标不对应的概括，不能完成相同的观察任务。

**具体修法。** 音高复用或扩展已有 `PitchChartDescriptor`（[AccessibilitySupport.swift:50](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/AccessibilitySupport.swift:50)），给出时间—频率序列、断点与有意义摘要。频谱提供主要峰值的频率/幅度与可逐项访问的列表；声谱图提供所选时刻的频谱摘要及浏览替代。不要为每帧更新自动连续播报；暂停后允许细读。

**证据边界。** 未运行 VoiceOver，因此不宣称已确认朗读顺序或无法聚焦；缺少图表描述器和数据替代接口是代码可确定的。

### M08 · P2：图表降级通过错误标题打断仍正常进行的录音

**位置。** [AnalysisViewModel.swift:356](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/AnalysisViewModel.swift:356) 的实时音高处理错误只设置 `recordingError`，不结束录音。对应中文文案为“实时音高暂时不可用，录音仍在继续，结束后将进行完整分析”。[ScoringView.swift:44](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/ScoringView.swift:44) 却统一使用“无法开始录音”弹窗标题；第 64–66 行没有排除正在录音的状态。

**影响。** 用户正在读语料时被模态弹窗截断。标题暗示录音失败，正文又让用户继续，容易导致停顿、重读和对本次结果的不信任。

**具体修法。** 实时图形不可用时在原图区域给出非阻断说明“实时曲线暂不可用，录音正常”，主录音状态与停止按钮保持有效。真正的启动失败、权限拒绝、写入失败分别使用准确标题及恢复动作。

### M09 · P2：评分图表的空状态不能区分准备中、正在录音但无声、尚未开始

**位置。** [ScoringView.swift:176](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/ScoringView.swift:176) 只在 `snapshot.samples.isEmpty` 时显示“开始后显示实时测量结果”，没有读取录音状态。音高样本可包含 `nil`（无声），但数组非空时提示消失；[MonitorCharts.swift:195](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorCharts.swift:195) 对无声只断开线、不画点。因此一段纯无声音频会留下没有原因说明的空图。相比之下，[MonitorViews.swift:185](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViews.swift:185) 已区分 preparing、waiting 和 unvoiced。

**影响。** 用户点过录音后仍可能短暂看到“开始后”的未开始语义；麦克风工作但未检测到有声信号时只剩空画布，让用户无法区分“没有声音”“权限没开”“还没准备好”。

**具体修法。** 用业务状态和数据质量共同派生提示：未开始显示开始指引；准备中显示麦克风准备；录音中无有声片段显示“正在录音，请自然朗读”；音高超出显示范围则保留数值并明确范围限制；数据恢复时只替换图内提示，外部布局不重排。

### M10 · P3：声谱图页面在工具身份与窗口反馈上失去相邻工具的一致性

**位置。** [PracticeSpectrumView.swift:35](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeSpectrumView.swift:35) 标题为 `practice.spectrum.title`，当前中文本地化实际也是英文 `Spectrum`；它构建的模型仍是 `.spectrum`，见第 78 行。共享 accessory [MonitorTabAccessory.swift:32](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorTabAccessory.swift:32) 只从 `model.kind.titleKey` 取名，所以热图页面控制条显示“实时频谱”，与另一张单时刻曲线图的控制条同名，无法区分两种显示任务。[PracticeSpectrumView.swift:191](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeSpectrumView.swift:191) 的设置按钮只有齿轮，也没有选中窗口的 accessibilityValue；其他监测页的 [MonitorViews.swift:293](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViews.swift:293) 则至少定义了“窗口＋当前秒数”及 accessibilityValue。窗口还会决定回放哪一段音频，见 [MonitorViewModel.swift:261](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViewModel.swift:261)。

**影响。** 用户需要自行判断 `Spectrum` 和“实时频谱”两个入口是什么关系；热图页的当前 5/10/30 秒设置只有打开菜单才容易确认，标准播放图标又没有明确说明是播放当前位置之前的窗口。

**具体修法。** 将显示身份（实时音高、实时频谱、声谱图）作为 accessory 参数传入，而非完全由分析类型决定；声谱图沿用窗口显示与 accessibilityValue；对回放明确标为“回放这 10 秒”，并显示所选范围。设置可继续使用系统 Menu/Picker，无需另造弹窗。

### M11 · P3：等宽数字没有稳定单位和缺失值占位

**位置。** [MonitorViews.swift:144](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViews.swift:144)、[ScoringView.swift:91](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/ScoringView.swift:91)、[PracticeSpectrumView.swift:94](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeSpectrumView.swift:94) 都把可变长度数字 Text 与 Hz 组成 HStack，但没有固定数字列宽。`.monospacedDigit()` 能稳定同位数的字形宽度，不能稳定“— → 99.9 → 100.0 → 1000.0”的字符串宽度。

**影响。** Hz 的位置随位数变化移动，初始化/无声切换的变化尤其大。与快速刷新叠加后读数缺少固定锚点。该项属于局部精修，不应抢占前述状态和流程问题的优先级。

**具体修法。** 按当前工具的合理位数预留数字区域，数字靠固定边缘对齐，单位保持固定基线；缺失值在同一占位中显示。动态大字号时让单位及次要指标重排，避免一味缩小文本。实际宽度和美观程度需渲染确认。

## 全文件与全部视图类型覆盖

| 文件 | 覆盖的视图/类型 | 当前可达性 | 可保留部分、未发现显著问题的部分 | 关联发现/风险 |
| --- | --- | --- | --- | --- |
| [MonitorViews.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViews.swift) | `MonitoringHubView`、`SpectrumMonitorView`、`PitchMonitorView`、`MonitorPage`、`MonitorReadout`、`MonitorInstrument`、`MonitorTimelineControl`、`MonitorWindowMenu`、`MonitorHelpView`、`MonitorReviewModifier`、`MonitorScreenPreview`、五个 Preview | `PitchMonitorView`/`SpectrumMonitorView` 经训练 Hub 和 `ContentView` route 可达；`MonitoringHubView` 只有定义，当前主路由不用；review modifier/preview 为 DEBUG | 宽窄布局与大字号重排；主读数/单位基线；系统 Slider/Menu/Picker；准备中、尚无采集、无有声数据的独立提示；帮助用系统 sheet/List；无装饰性的整页动画 | M02/M04/M06/M07/M11。弹窗无就地恢复、图表文本大小与首屏密度见待验证清单 |
| [MonitorTabAccessory.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorTabAccessory.swift) | `MonitorAccessoryContent`、回放、回退、主录音按钮组合 | 三个 Monitor 工具均通过主 Tab accessory 使用 | 44pt 控制占位；准备中禁止动作；可用性 gate；回放图标切换在 Reduce Motion 下使用 identity；状态变化未驱动整个页面动画 | M02/M03/M10。大字号单行标题和三按钮拥挤、rotate 的系统 Reduce Motion 行为待验证 |
| [MonitorAccessoryState.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorAccessoryState.swift) | `MonitorAccessoryState`、环境键 | 当前主路由与 Preview host 使用 | 模型身份比较防止旧页面错误清除新 accessory；替换会话先停旧会话 | M04；切离只处理 Monitor，使 M01 更明显 |
| [MonitorFrequencyGauge.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorFrequencyGauge.swift) | `MonitorFrequencyGauge`、`MonitorFrequencyRuler`、`MonitorGaugeScale` | 音高、频谱、声音评分使用；声谱图页不使用 | 指针与真实频率共用对数映射；无信号不伪造 0Hz；刻度有测量后的碰撞检查；端点优先；高对比描边变化；读屏提供当前值和范围 | 标尺字体最高 14pt、大字号可读性；超范围读数无指针时如何解释；见风险清单 |
| [MonitorCharts.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorCharts.swift) | `MonitorSpectrumPlot`、`MonitorPitchPlot`、`MonitorPitchGrid`、`MonitorPitchTimeAxis`、`MonitorPitchTrace`、`MonitorChartLayout` | 频谱/音高/评分主路径可达 | 网格与实时线分离；谱峰标记与大读数共用 peak；音高无声断线；真实时间点标记；图表刻度主动稀疏；高对比线宽；未给高频数据附加 spring | M06/M07；字体 cap 与低对比网格需渲染。未测性能，不据代码宣称流畅 |
| [MonitorSpectrogramPlot.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorSpectrogramPlot.swift) | `MonitorSpectrogramPlot`、`MonitorSpectrogramHeatmap`、`MonitorSpectrogramFrequencyAxis`、`MonitorSpectrogramTimeAxis`、`MonitorSpectrogramCursor`、`MonitorSpectrogramLegend`、style/layout | 声谱图当前主路径可达 | 固定窗口列绘制；缺失列留空而不拉长；游标用同一时间映射；色标给真实 dBFS 范围；图轴主动避碰；主动定义技术图时间从左向右 | M07；强色块、超大字号图内空间、色条含义、对比需渲染 |
| [MonitorPresentation.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorPresentation.swift) | `MonitorPitchWindow`、`MonitorPresentation` | 当前所有 Monitor 数据表达共用 | 窗口曲线与范围读数共享快照；回放使用固定 playbackRange；只在实际数据变化时重建窗口；延迟/缺失数据不无限保持为实时 | M06；0.4s 大读数有效期与图标记 0.15s 的短时不同显示，需运行观察是否造成歧义 |
| [MonitorViewModel.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViewModel.swift) | `MonitorKind`、`MonitorViewModel`、`MonitorPlaybackDelegate`、两类 preview factory | 主路径可达；fixture 仅 DEBUG | 清楚的 idle/preparing/live/paused/replaying；generation 防旧异步结果回写；快速重入等待旧音频收尾；回放暂停后延续原范围；失败保留已有数据；中断暂停不自动再开麦克风；显示更新有节制 | M02/M03/M04/M06/M10。状态模型正确不等于状态已被界面解释 |
| [MonitorTimeline.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorTimeline.swift) | `MonitorSpectrumFrame`、`MonitorTimeline` | 当前数据/回放路径 | 环形缓冲限制 60 秒；音频时钟驱动；暂停不加入空白时间；音高无效数据作为 gap；回放样本边界一致；峰值明确阈值和有效性 | M04/M06；这些是工程依据，不单独作为视觉问题 |
| [MonitorAudioCapture.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorAudioCapture.swift) | update、capture、engine protocol/adapter、ingress、error | 当前采集路径 | 音频工作不在 UI actor；取消/停止统一；停止等待在途回调；缓冲超限明确失败而非无声丢数据；无新设计问题 | 错误上屏仍只有一般 alert，具体感受由 UI 决定；未做性能测试 |
| [MonitorSpectrumAnalyzer.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorSpectrumAnalyzer.swift) | FFT analyzer、allocation error | 当前频谱与声谱图使用 | 连续音频分窗、固定频率 bins、dBFS 校准、窗口不足不伪造补值；无独立界面问题 | 未验证算法性能/精度，不将代码评审替代测试 |
| [MonitorSpectrogramRasterizer.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorSpectrogramRasterizer.swift) | column、rasterizer | 声谱图当前路径 | 时间身份稳定；列像素复用；窄谐波保留；频率边界固定；幅度和 legend 同量纲；没有发现需单独提报的交互问题 | 调色及亮度需实际画面评估，不凭RGB判定“刺眼” |
| [MonitorWaveEncoder.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorWaveEncoder.swift) | PCM16 in-memory WAV encoder | 回放路径 | 内存编码匹配临时音频语义，避免额外持久录音；没有独立视图或设计问题 | 不涉及视觉布局 |
| [ScoringView.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/ScoringView.swift) | `ScoringView`、`ScoringReadout`、`ScoringElapsedTime`、`ScoringInstrument`、`ScoringPitchChart`、clock | 训练 Hub 的声音评分主路径可达 | 稳定模型；读数/时钟/曲线各自订阅；宽窄布局；大字号调整；10 秒曲线范围由 snapshot 保持；语料固定纵向大小 | M01/M05/M07/M08/M09/M11 |
| [PracticeSpectrumView.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeSpectrumView.swift) | `PracticeSpectrumView`、readout、instrument、timeline、settings、help、factory、Preview | 训练 Hub 的声谱图 route 可达；最后单页 Preview 仅预览 | 原生滚动、Slider、Menu；读数大字号垂直重排；手势无额外 easing；帮助内容可滚动；固定窗口语义 | M02/M03/M04/M07/M10/M11；独立 Preview 缺共享 accessory host，不能证明完整控制条设计 |

## 关键状态逐项检查

| 状态/操作 | 当前代码表现 | 可保留部分或缺口 |
| --- | --- | --- |
| 首次进入监测 | —、空坐标、开始提示；下方回放/回退禁用 | 没有把无数据伪装成0；主状态未可见，M02 |
| 请求麦克风/准备分析器 | 进入 preparing；主按钮 spinner、禁用；Monitor 图内显示准备 | 未知进度不伪造百分比；主控制不可取消，仍可系统返回 |
| 用户拒绝麦克风 | fail → idle，错误 alert | 有真实失败；alert只有“好”，可考虑就地设置入口，见待验证 |
| 正常采集 | 数字、标尺、曲线/热图更新 | 共享真实值，不用高频数值翻转；状态必须可见，M02 |
| 无有声信号 | Monitor pitch有unvoiced提示，评分只按数组空判断，频谱/声谱图保留实际噪声/能量图 | M09；频谱的无声并非没有音频，不应一律展示空状态 |
| 暂停 | 硬件停止，当前会话可回放 | 保留数据正确；视觉状态缺失，M02 |
| 拖动 | Slider即时seek，先暂停，更新游标/窗口 | 原生替代操作和直接映射可保留；窗口尺度变化M06，暂停说明M02 |
| 倒回5秒 | 先暂停，再clamp到有效范围；有效动作才触觉 | 映射合理；旋转效果在Reduce Motion下的系统处理仍未验证 |
| 开始回放 | 先暂停采集，回放当前位置之前的窗口；在最早起点时向后播放 | 防反馈/保留音频合理；“播放什么”说明可见性不足，M10 |
| 回放中暂停再播放 | 保留原playbackRange，从当前播放位置继续 | 状态连续性实现可保留；主按钮错误名称M03 |
| 回放完成 | 状态paused，游标到末端 | 不擅自重新开麦合理；需可见“回放完成/已暂停”，M02 |
| 切5/10/30秒窗口 | 实时采集继续，回放/准备中会暂停；更改窗宽 | 选择源单一；对回放影响需要更明确，M10 |
| 打开帮助 | 系统sheet，警告暂不抢帮助呈现 | 保持系统层级；帮助不应承载唯一的会话状态/退出后果 |
| 退出监测/切Tab | stopForLeaving清空 | M04；不将普通导航与结束会话混为一体 |
| 评分录音切Tab | 容器持有模型，控件隐藏，无结束调用 | M01 |
| 音频/路由中断 | Monitor暂停、不自动恢复；评分的interruptCapture未接入 | Monitor避免无意开麦可保留；双方生命周期应有清晰一致的产品约定 |
| 音频缓冲超限/播放失败 | 显式错误，已有时间线保留 | 不是假成功；目前恢复入口主要仍是控制条，需要状态可见 |

## 待渲染/设备验证风险，不作为已验证缺陷

- **大字号控制条。** `MonitorAccessoryContent` 标题固定单行并 `minimumScaleFactor(0.8)`，旁边三个 44pt 按钮和 4pt 间距保持横向（[MonitorTabAccessory.swift:24](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorTabAccessory.swift:24)）。应验证窄屏、最长中文/德语/辅助字号是否还能读出工具与状态；不能仅凭修饰符断言裁切。
- **图表与标尺文字上限。** 图表布局 [MonitorCharts.swift:254](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorCharts.swift:254) 和标尺 [MonitorFrequencyGauge.swift:72](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorFrequencyGauge.swift:72) 将刻度字体限制到14pt。这有保住曲线空间的明确意图，但应验证低视力用户是否仍能比较数据；M07补齐后可提供图表替代阅读，不必一律放大全部刻度。
- **声谱图在超大字号时的实际绘图区。** [PracticeSpectrumView.swift:17](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeSpectrumView.swift:17) 图高至少300pt；[MonitorSpectrogramPlot.swift:165](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorSpectrogramPlot.swift:165) 轴边距随字号扩大。需检查频率标签、时间单位与热图是否挤压，并看色标是否还能一眼理解。
- **强色块与对比。** 声谱图用固定蓝紫—橙黄幅度色谱，能表达能量，与其他白底细线工具差异很大；是否“刺眼”取决于真实亮度、主题与内容。不能仅凭源码颜色值下结论。左侧竖色条与下方幅度legend并存是否造成频率/幅度混淆也需视觉验证。
- **减少动态效果。** 回放图标替换与共用按压缩放有明确 `accessibilityReduceMotion` 分支；回退 `.symbolEffect(.rotate)` 没有同样的显式分支（[MonitorTabAccessory.swift:89](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorTabAccessory.swift:89)）。需核实该SDK下系统是否自动替代，不能直接断言违反减少动态效果。
- **触觉。** 用户主动按钮动作触发一次轻触觉，没有每帧触觉。力度、延迟和是否与系统反馈叠加必须真机检查；本轮没有该证据。
- **权限恢复。** alert只有确认，文字引导用户手动去系统设置。可考虑“打开设置”，但是否需要与平台原生许可体验一起验证，暂不把它提升为主报告核心问题。
- **跨图数值过期阈值。** Monitor 当前值允许最近0.4秒样本，而图内marker只显示最近0.15秒样本（`MonitorPresentation.swift:87`、`MonitorCharts.swift:228`）。源码意图是避免延迟值无限保留；应在短暂停顿时观察数字、指针、曲线marker是否让人误以为不一致，再决定是否统一阈值。
- **性能。** 已看到拆分静态网格、按需快照、非主线程FFT/栅格化、显示更新限频。它们是合理工程措施，不构成实际帧率、响应延迟或流畅度证据。本轮不运行性能检查。

## 建议后续验证顺序

先用明确的状态契约修复 M01–M04，然后处理评分主任务焦点及图表替代阅读 M05–M09，最后整理工具命名、数字锚点及视觉细节 M10–M11。每一步验收检查默认态、操作中、结束态、中断/快速反向；不以添加动画数量或通过构建替代交互验收。当前用户明确要求不用模拟器，因此以上验证步骤仅作为后续清单，本轮没有执行。

## 本轮源码指纹

生成时间（Asia/Shanghai）：2026-10-06T20:43:15+08:00。用于识别并行修改后行号是否已经漂移，不代表测试结果。

| 文件 | 行数 | SHA-256 前16位 |
| --- | ---: | --- |
| `PitcheeApp/Monitoring/MonitorAccessoryState.swift` | 37 | `389f7d5e37e37ad7` |
| `PitcheeApp/Monitoring/MonitorAudioCapture.swift` | 349 | `9c03fecd1f5e7ad0` |
| `PitcheeApp/Monitoring/MonitorCharts.swift` | 302 | `0d004dd428ef67ae` |
| `PitcheeApp/Monitoring/MonitorFrequencyGauge.swift` | 156 | `f385a524dbbb4cb3` |
| `PitcheeApp/Monitoring/MonitorPresentation.swift` | 126 | `3fec2ed72f83642b` |
| `PitcheeApp/Monitoring/MonitorSpectrogramPlot.swift` | 182 | `9b78a18c0795500d` |
| `PitcheeApp/Monitoring/MonitorSpectrogramRasterizer.swift` | 107 | `8d1f98730651df51` |
| `PitcheeApp/Monitoring/MonitorSpectrumAnalyzer.swift` | 114 | `1266cae87b506947` |
| `PitcheeApp/Monitoring/MonitorTabAccessory.swift` | 128 | `3558ec3e4d2c36bc` |
| `PitcheeApp/Monitoring/MonitorTimeline.swift` | 223 | `c7f69ae1f1a5a513` |
| `PitcheeApp/Monitoring/MonitorViewModel.swift` | 569 | `f6254facccb79ea9` |
| `PitcheeApp/Monitoring/MonitorViews.swift` | 399 | `8adb88b43f01a42a` |
| `PitcheeApp/Monitoring/MonitorWaveEncoder.swift` | 31 | `5b63933f51450fad` |
| `PitcheeApp/Practice/ScoringView.swift` | 196 | `e7bc60f02c6a74e9` |
| `PitcheeApp/Practice/PracticeSpectrumView.swift` | 243 | `9653e23ab0e09f61` |
