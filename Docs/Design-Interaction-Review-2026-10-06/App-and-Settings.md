## App、引导、设置、钢琴与诊断

依据为当前源码和简体中文资源；全部属于静态审查。没有据此断言实际裁切、对比度测量结果、音频输出或触觉效果。

### A1 · P1 · 首页的第一焦点与初次使用任务错位

主 Tab 默认选趋势页；依次显示日期筛选、分析次数/打开天数、综合分、自然度/平均音高，最后才是无记录说明。两张使用统计卡有彩色图标、大数字和至少 138 pt 容器。没有录音时所有无值指标仍保留，空状态没有开始操作。用户要先解释一份报表才能知道如何获得第一次反馈。

位置：[ContentView.swift:45](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:45)、[页面顺序:250](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:250)、[空状态:611](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:611)。

建议：首次使用用“录一段，了解当前声音”与开始按钮构成主体；已有记录时先展示最近一次观察和下一项练习。次数/天数收为辅助统计。卡片本身可保留，先纠正信息权重。

### A2 · P2 · 指标颜色跨页面换含义，涨跌颜色又混入好坏判断

首页综合分大数字蓝色、同卡曲线紫色；自然度紫色、音高青色。详情映射变成综合分跟随主题、自然度青色、音高橙色。与此同时，通用 trendText 把任何上升标绿、任何下降标红，包括平均音高。男性向练习目标下音高降低也会收到红色提示，女性向也不意味着音高越高越好。

位置：[ContentView.swift:365](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:365)、[曲线:391](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:391)、[指标卡:503](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:503)、[趋势色:650](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:650)、[InsightsData.swift:78](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsData.swift:78)。

建议：按指标统一颜色；品牌色、指标色与结果状态色分别定义。Hz 的变化用中性色和方向，明确有目标区间时再表示接近或远离目标。

### A3 · P2 · 大数字缺少单位与时间，辅助解释又过弱

首页音高卡传入一位小数，没有 Hz；综合分主值没有标明哪一天的最近值。基准解释分散到 caption/caption2，部分使用 tertiary。大数字具有很高视觉权重，却无法在卡内回答“什么时候、相对于什么”。

位置：[ContentView.swift:362](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:362)、[音高值:510](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:510)、[基准说明:583](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:583)。

建议：数值旁补单位和“最近一次·日期”，变化明确写比较口径。必要解释使用可读的 supporting 角色；详细统计仍留在详情。

### A4 · P2 · 引导、首页和钢琴使用固定字体，放大文字的行为不统一

引导页标题、正文、功能说明和按钮使用固定 43/34/20/17/16/15/13 pt；中文标题还继承负 tracking。首页核心数字与钢琴频率也用固定字号；这些位置没有 Scoring/Monitor 已使用的 ScaledMetric。结果是系统字号变化时部分文案增大、部分关键值仍保持原大小。该结论是代码层面的缩放策略不一致，实际挤压和裁切未验证。

位置：[OnboardingView.swift:134](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/OnboardingView.swift:134)、[功能说明:304](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/OnboardingView.swift:304)、[ContentView.swift:336](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:336)、[钢琴频率:799](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:799)。

建议：统一 display/title/body/supporting 字体角色；正文用语义字体，展示值用相对缩放，放大字号时相应改为单列。中文不直接继承英文标题的负字距规则。引导页固定底部主按钮和可滚动正文值得保留。

### A5 · P2 · 主题色设置没有展示它对真正内容的影响

ColorPicker 允许任意不透明颜色，AppTheme 原样输出给文字、线条、图标和选中边框，没有按浅深色区分的可读变体。主题设置的预览只有一个色圆，没有真实文字或图表。选择白色用于浅色内容、黑色用于深色内容会产生低对比风险；这里没有测量运行时合成背景的对比度。

位置：[SettingsView.swift:241](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/SettingsView.swift:241)、[主题预览:269](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/SettingsView.swift:269)、[AppTheme.swift:12](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/AppTheme.swift:12)。

建议：分别定义适合文字、图表和装饰面的主题派生色，给出浅/深背景上的真实组件预览。保留用户选色和恢复默认能力。

### A6 · P2 · 钢琴的空间关系和反馈都不够明确

24 个半音从 F#2 到 F4 放进 adaptive 网格；两列时就是 12 行，同等玻璃表面的按键需要反复滚动寻找，相邻音符的位置随列数改变。蓝/粉/灰分区没有说明。页面命名“钢琴键”，却没有键盘或音阶轴的稳定空间关系；若用途是找参考音，缺少当前音和相邻半音的紧凑操作。

更确定的状态缺口是：触摸后立刻设置 activeNote、触发触觉，但声音引擎准备/激活失败只写日志，页面没有失败状态。录音仍占用会话时激活钢琴会被拒绝，用户可能看到按键反馈却听不到声音。还存在读屏语义差距：忽略子内容后只朗读音名，没有暴露 Hz；hint 声称“按住可持续发声”，实际只提供单次播放 accessibilityAction。

位置：[ContentView.swift:727](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:727)、[反馈:747](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:747)、[颜色和语义:783](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:783)、[PianoSoundEngine.swift:22](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Audio/PianoSoundEngine.swift:22)、[准备失败:65](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Audio/PianoSoundEngine.swift:65)、[AudioSessionCoordinator.swift:32](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Audio/AudioSessionCoordinator.swift:32)。

建议：明确“参考音”任务，以当前音、Hz 与相邻音形成稳定操作区；保留全音列表时按音区分组并提供用途说明。音频可用/被占用/失败要有可见状态，读屏补频率及持续/停止操作。现有松手、取消、滚动冲突和离页停止处理可保留。

### A7 · P2 · 换图标的等待、失败与不支持状态没有交代

点击后所有选项被禁用；完成回调只有 error == nil 才更新选择，失败不显示任何消息。设备不支持时全部禁用但 footer 仍说“选择后会立即更新”。当前行内容和选中反馈是清楚的，缺的是结果状态。

位置：[AppIconSettingsView.swift:76](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/AppIconSettingsView.swift:76)、[完成回调:101](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/AppIconSettingsView.swift:101)。

建议：在被选项中显示短暂进度；失败保留原勾选并解释可重试；不支持时显示原因。无需重做列表或缩略图。

### A8 · P2 · 自愿反馈步骤仍顶着“正在分析”的标题

ScoreStudyFeedbackView 只在用户已启用本地对照且被抽中时出现，具有跳过/无法判断按钮，退出可自动跳过；这些应保留。但其父级把 awaitingFeedback 和 analyzing 合并成同一个导航标题，并隐藏返回。屏幕此时需要人回答问题，却说正在分析；30 秒自动继续的说明位于选项和跳过按钮之后。

位置：[RecordingAnalysisView.swift:16](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:16)、[状态标题:43](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift:43)、[LocalScoreStudyView.swift:102](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Diagnostics/LocalScoreStudyView.swift:102)、[AnalysisViewModel.swift:459](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/AnalysisViewModel.swift:459)。

建议：使用现有“练习自评”标题，顶部直接表达可跳过及会继续分析。保留先反馈后显示分数的研究顺序；无需为此把它改为强制表单。

### A9 · P3 · 设置入口与名称不相符

第四个 Tab 的图标和名称是 info.circle/“关于”，内部首组却是声音目标、隐私、主题色，另有图标和本地工具。用户修改偏好时需要先猜“关于”里有设置。

位置：[ContentView.swift:171](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift:171)、[SettingsView.swift:32](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/SettingsView.swift:32)。

建议：入口命名为“设置”，版本和引擎等“关于”内容作为内部组。保留系统 Form/Picker/Toggle，无需装饰性重构。

### 已覆盖且不应为了重设计而改变的部分

- PitcheeApp 存储失败显示独立 ContentUnavailableView，中文已明确“解锁后重新打开 App，现有记录未重置”。没有证据应换成复杂弹窗或重置流程。
- VoicePreferenceCard 同时用选中形状、边框和读屏 selected trait；PrivacyPromiseView 信息成组。其说明应随现用单次录音/临时音频行为校准，避免沿用未接入 A/B 的“最多两段”表述。
- VoicePreferenceSettingsView 使用系统 inline Picker、自动保存说明，PrivacySettingsView 用系统分组且文案允许多行；不需要重做组件。
- LocalDiagnosticsView 与 LocalScoreStudyView 是主动进入的高级本地工具，已有说明、错误状态、过期/限额文案与分组统计。信息较多不是主流程难受的主要来源；可后续折叠明细，但优先级低。
- AccessibleStack 与 AccessiblePickerStyle 已提供大字号/Assistive Access 重排；问题在于实际核心页面没有一致复用这种策略。
- FoldAwareArrangementView 使用系统分区能力并保留 regular 分支。未运行，不声称折叠布局通过或失败。
- DebugPreviewData/Store 是模拟数据设施；Preview 包装器是审阅入口，不视为产品中的新页面。
