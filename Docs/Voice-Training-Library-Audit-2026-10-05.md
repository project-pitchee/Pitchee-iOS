# 嗓音训练知识库：科学性、准确性、质量与风格审查

审查日期：2026-10-05（Asia/Shanghai）  
对象：当前工作区 Docs/Voice-Training-Library 下 8 个模块、49 篇 Markdown 文章，以及 README、打包 JSON 和直接向用户解释推荐理由的代码。  
性质：文献与内容审查；文中优先级表示编辑修订顺序，不是对任何读者的医学诊断。

## 结论

**现稿需要实质性修订，不宜按 README 所称“基于现代语音声学、运动学习与临床医学循证的专业教程”直接面向自学者发布。** 内容覆盖面与主题组织可以保留，具体解释、练习指令、引用和语言需要重新审校。

最主要的问题是：把模型输出解释成身体内部状态，把未经验证的数字写成临床标准，把鼓励性的说法写成训练效果保证。它们会影响读者决定是否继续练习、是否就医，以及如何理解自己的声音。文末加一条免责声明不足以修复正文中的具体错误。

可保留的设计包括：同句 A/B 回听、一次只探索一个变化、关注主观体验、录音环境排查、在出现不适时暂停，以及从短句逐步过渡到生活交流。SOVT、共鸣探索、音高练习等主题本身也值得保留，但应交代适用范围、局限、练习反馈和停止条件。

## 审查范围与证据边界

- 完成 49 篇文章逐篇审阅；附录按文章列出具体位置、问题和修改方向。
- 逐项访问用户提供的 9 个资源。Wang 等论文核对公开摘要和书目信息，未取得付费全文。Sheffield 核对资源索引及可见说明，未逐个读取所有嵌入式课件、附件和视频。TruVox 通过浏览器核对 Help/Suggestions；CNTT 核对公开页面，未取得其受协议约束的完整教材。
- 补充核查量表作者 La Trobe 的官方说明和授权简体译本、WPATH SOC8，以及与健康建议相关的专业资料。没有把社区经验自动提升为临床疗效证据。
- 核对当前 Core 评分、自然度输入与 VFP 输出，以及 iOS 推荐说明。两份 JSON 中的 49 篇 rawContent 均与当前 Markdown 一致，说明问题同时存在于待打包内容中。
- 审查针对当前包含未提交修改的工作区。原文章、App 实现和评分参数未修改；本次只新增审查报告及证据清单。

证据状态使用三种表达：**确认有误**（与可见源码或原始资料直接冲突）；**证据不足**（所引材料不能支持这么强的结论）；**待核实**（需要全文、具体研究或未访问材料，不能断言其不存在）。

## 优先修订的问题

### 1. P1：取消“模型分数 = 声带状态/健康诊断”的解释

代表位置：[自然度文章第 12 行](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-NATURAL-LOW-01-自然度重构-声带过度撞击与声门漏气消除.md:12)、[安全红线第 16 行](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-08-Health-Psychology-Clinical/HEALTH-REDLINE-01-安全红线-刺痛干涩与嘶哑失声的紧急处置.md:16)、[TWVQ 第 54 行](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-08-Health-Psychology-Clinical/HEALTH-TWVQ-01-科学自评-跨性别女性嗓音问卷TWVQ-SC与生活质量量表.md:54)。

**确认有误：**当前自然度输出来自模型对声学 embedding 特征的预测，代码没有输出文中所声称的 CQ、Jitter、Shimmer、HNR，也没有诊断声门闭合不全、肌紧张性发声障碍或声带出血的接口。VFP 是窗口模型概率的汇总，不能直接等同于声道容积或共振峰测量。即使某些模型特征与音质相关，也不能反向确定病因。

源码依据：[naturalness.cpp:16](/Users/dannyfeng/Documents/Pitchee/Dependencies/PitcheeCore/src/naturalness.cpp:16)、[analyzer.cpp:553](/Users/dannyfeng/Documents/Pitchee/Dependencies/PitcheeCore/src/analyzer.cpp:553)、[analyzer.cpp:637](/Users/dannyfeng/Documents/Pitchee/Dependencies/PitcheeCore/src/analyzer.cpp:637)。项目自己的[练习说明第 29 行](/Users/dannyfeng/Documents/Pitchee/Docs/Guided-Practice.md:29)已明确录音门槛不是健康诊断，自然度偏低不应生成确定的发声问题建议。

修改：解释分数的输入、范围、比较条件和不确定性；症状与舒适感独立记录。不能由高分排除病变，不能由低分认定某块肌肉需要“松绑”或“强化闭合”。

### 2. P1：重写急性不适处理，删除自行诊断和固定“急救 SOP”

代表位置：[安全红线第 24 行](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-08-Health-Psychology-Clinical/HEALTH-REDLINE-01-安全红线-刺痛干涩与嘶哑失声的紧急处置.md:24)、[第 38 行](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-08-Health-Psychology-Clinical/HEALTH-REDLINE-01-安全红线-刺痛干涩与嘶哑失声的紧急处置.md:38)。

文章把刺痛、异物感、嘶哑和失声分别归为出血、脱水、水肿和肌痉挛，随后给出“绝对禁声 4 小时”“不听语音、不在脑海默读”“60℃ 热水贴杯吸入 10 分钟”“次日蜂鸣清亮即可恢复训练”。这些推断和统一时程没有得到所引资料支持。热水蒸汽操作还引入烫伤风险，不能包装成已证实的消肿措施。[NIDCD 嗓音护理建议](https://www.nidcd.nih.gov/health/taking-care-your-voice)、[英国烧伤中心关于蒸汽吸入伤害的研究](https://pmc.ncbi.nlm.nih.gov/articles/PMC7456299/)。

修改：出现疼痛、明显费力或新发嘶哑时停止当前练习，减少用声，不反复试音验证“是否恢复”。按症状性质安排就医；呼吸困难等紧急征象应立即求助，用声后突发明显声音改变应及时评估。持续或反复的问题由耳鼻喉/嗓音专业人员查明，恢复练习不能只依据一次哼鸣或 App 分数。

### 3. P1：删除未经验证的 TWVQ-SC 阈值及“高分所以只剩心理问题”的归因

代表位置：[TWVQ 第 34 行](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-08-Health-Psychology-Clinical/HEALTH-TWVQ-01-科学自评-跨性别女性嗓音问卷TWVQ-SC与生活质量量表.md:34)、[第 53 行](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-08-Health-Psychology-Clinical/HEALTH-TWVQ-01-科学自评-跨性别女性嗓音问卷TWVQ-SC与生活质量量表.md:53)。

可保留：公开摘要确实报告 260 名跨性别女性与 128 名顺性别女性，Cronbach α=.969、ICC=.841。研究评估的是简体中文版问卷的信效度，并不验证 Pitchee 分数或任何训练课程。[Wang 等，2022](https://pubs.asha.org/doi/10.1044/2022_JSLHR-21-00685)。

需要删除：“≤45 代表毫无心理负担”“≥75 且 App≥85 说明核心障碍已非声学技巧”“所有人的目标应低于 45–50”。量表作者说明没有可用于统一判定的常模，题项的变化还受生活情境影响。高困扰分不能自行被解释为社交恐惧或冒充者心理。[La Trobe 官方 FAQ，第 3 页](https://www.latrobe.edu.au/__data/assets/pdf_file/0010/1393363/TGV-Resources.pdf)。

待核实：本次未取得论文全文，公开摘要也未列出 34.8±6.2、76.4±19.8，因此这两组数值尚未核实。即使它们最终证实是样本统计，也不能直接变成个人临床阈值。

确认有误：部分“题项举例”与[授权简体问卷](https://www.latrobe.edu.au/school-allied-health-human-services-and-sport/ds-documents/TWVQ-Chinese-Simplified-Chinese-Authorised-Translation.pdf)不一致。自行改写的内容应明确是编辑撰写的情境例子，不能冒充授权量表原题；正式量表计分必须保持对应版本的题目与说明。

### 4. P1：改正手术前必须训练 6–12 个月的说法

代表位置：[就医指南](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-08-Health-Psychology-Clinical/HEALTH-CLINICAL-01-就医指南-何时寻求嗓音支持专家与咽喉科医生专业帮助.md)。

**确认有误：**文章把固定时长的训练无效写为 WPATH/ASHA 规定的手术前提。WPATH SOC8 第 14 章说明推荐提供术前/术后支持，并明确相关条款不意在要求所有人接受术前嗓音训练。具体手术团队或保险条件应另行核对，不能冒充通用指南。[WPATH SOC8](https://pmc.ncbi.nlm.nih.gov/articles/PMC9553112/)。

修改：介绍行为训练、激素相关变化和手术的不同作用、局限与个体选择；鼓励与专业团队讨论适应证、风险、恢复和后续支持。

### 5. P1/P2：停止从分数变化推断训练正确性

代表位置：[A/B 下降文章第 18 行](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-06-Guided-Practice-AB/PRACTICE-AB-DROP-01-AB复测得分下降-动作重塑期的正常波动.md:18)、[第 33 行](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-06-Guided-Practice-AB/PRACTICE-AB-DROP-01-AB复测得分下降-动作重塑期的正常波动.md:33)。

“B 分数下降证明打破错误代偿”“自然度升高说明健康松弛”“舒适即方向完全正确”均超出可观察信息。两次录音受语料、响度、距离、疲劳、估计误差和规则阈值影响，也没有足够时间点建立 U 型学习曲线。项目的[原始 A/B 说明第 10 行](/Users/dannyfeng/Documents/Pitchee/Docs/Guided-Practice.md:10)已要求不以变化正负直接评价进步。

修改：将下降写为需要结合回听、环境和身体感受解释的一次差异，允许“无法判断”，不能自动诊断学习机制。分数区间也不应自动对应训练月数、技巧掌握、成熟程度或全天用声能力。

### 6. P2：修复具体算法事实错误，并将产品阈值与人体规律分开

代表位置：[中性音区文章第 42 行](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-LOW-F0-NATURAL-02-中性音区应用-基频不硬飙的女性化补偿.md:42)。

**确认有误：**该文声称 145–165 Hz 可能得 70–80 分，但当前女性向 profile 在 F0≤165 Hz 时按自然度分支封顶 59 或 20，均不能到 70。[scoring.cpp:86](/Users/dannyfeng/Documents/Pitchee/Dependencies/PitcheeCore/src/scoring.cpp:86)。应修正当前规则说明，同时指出该限制只是软件规则。

[连续评分文章第 17 行](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-CONTINUOUS-01-连续评分逻辑与各指标协同进展.md:17)把 50% 的软件权重说成“印证声学事实”，属于循环论证。数学公式与当前代码基本一致不代表权重、165 Hz 阈值或任何分数段已经获得临床验证。

### 7. P2：去掉固定性别音区、感知概率和生理百分比保证

代表内容包括：“190–220 Hz 黄金频段”、将 145–165 Hz 定义为非二元声音目标、承诺 155 Hz 配合共鸣可让 95% 以上的人识别为女性、基频/共鸣/韵律的固定贡献百分比、“声带突然增重 30%”，以及每日 6 分钟 SOVT 显著减少破音的承诺。

这些数字需要明确研究、任务、语言、样本、测量方法及适用限制。当前引用无法支持它们成为个人训练标准。ASHA 虽列出部分研究中的感知频率范围，也同时强调避免过度关注平均基频，并以当事人的目标为中心；没有一种声音配置能定义所有女性、男性或非二元者。[ASHA Gender Affirming Voice and Communication](https://www.asha.org/practice-portal/professional-issues/gender-affirming-voice-and-communication/)。

修改：音高数据只作为解释性示例，先区分持续元音与连续言语、平均值与动态轮廓、群体统计与个人目标。非二元声音无需处在某个频率窗口。睾酮变化应写为个体差异显著，不承诺固定速度、降幅或生理百分比。

### 8. P2：对训练机制、剂量与身体意象做降格和澄清

需要重新核对的常见说法：SOVT“物理倒逼后部声门闭合”“挤出间质液”“声带肌纤维复位”；触摸胸骨即可判断声带重量/共鸣；固定喉位、咳嗽前控制喉头；按 20/30/45 分钟给出必然疲劳、水肿和失声时间线。

修改：把“前面有振感”“更轻/更厚”等标为某些人可能有帮助的感知提示，不能当作内部结构测量。短时、分散、可调整的练习日程可以保留为示例，不称为普适最优剂量。临床手法不应仅凭文字引导读者自行按压、牵拉或反复操纵喉部；保护性咳嗽也不能为了维持目标声音而受到妨碍。详见逐篇附录。

### 9. P2：重新建立可追溯的引用

统计口径为各篇“第四部分”的 Markdown 链接目的地：共 **99 条参考条目、12 个不同 URL**，其中 **31 条以不同名称引用同一个 ASHA 总览页面**，20 条指向 Sheffield 资源索引。相同来源可以重复引用，但每次均应使用真实标题，并定位到支持该主张的具体段落或研究。

例如自然度文章引用的“Acoustic Voice Assessment: Jitter, Shimmer and HNR”实际链接到 Gender Affirming Voice and Communication；许多写在书名号内的英文/中文名称无法在落地页确认为独立文献。应将自拟主题改为“相关主题：……”并保留真实资源名，或者提供真正可定位的篇名、作者、年份、DOI/章节。不能让读者误以为存在几十篇分别为这些结论背书的专门研究。

建议逐项记录：原始标题、作者/机构、年份或版本、URL/DOI、资源类型、支持的具体主张、核对范围及编辑核查日期。站点首页只适合做延伸阅读入口。具体样本量、诊断阈值、效果大小和训练处方必须有直接来源。

### 10. P2：修正基础语音学、解剖和录音术语

这些问题可以直接校正，无须等待训练效果研究：

- [元音变色第 14 行](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-HIGH-F0-MALE-02-口咽腔形变与元音变色提亮.md:14)把 /u/ 写成后低元音；它是后高圆唇元音。[IPA 元音表](https://www.internationalphoneticassociation.org/IPAcharts/IPA_charts_TI/IPA_charts_TI.html)。
- [鼻音自测第 26 行](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-VFP-NASAL-01-告别夹鼻音-软腭升降与真共鸣辨析.md:26)要求排除鼻音，例句却含大量鼻韵尾。正常鼻音也会受捏鼻影响，不能按它的标准判断异常。
- [普通话语调第 43 行](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-PITCH-MONOTONE-01-语调起伏-拯救机械音与上升语调.md:43)把带明显后升的调型称为半上声，应与低降/低平的半上声和上声变调分别说明。
- [嗓音卫生第 12 行](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-08-Health-Psychology-Clinical/HEALTH-HYGIENE-01-嗓音卫生全书-日常护嗓水分补给与科学冷身.md:12)对主要振动的膜部真声带上皮类型描述有误，应为复层鳞状上皮；具体组织学来源见健康附录。
- 录音文章需要区分浮点数取值范围与归一化满幅、削波谐波与混叠，以及 VAD 电平差代理与真正的信噪比测量。设备距离与增益影响 dBFS，它不能直接表示个人声带力量。
- [声音流动性第 3 行](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-05-NonBinary-Exploration/NONBINARY-FLUIDITY-01-嗓音流动性-声线自由切换指南.md:3)将 Bigender 译为“双性性格”，混淆性别身份与性格；应使用“双性别”等当事人认可的称谓。

## 九个指定资源如何使用

| 资源 | 本次核查范围与性质 | 适合支持的内容与限制 |
| --- | --- | --- |
| [Wang 等，2022，TWVQ-SC](https://pubs.asha.org/doi/10.1044/2022_JSLHR-21-00685) | 期刊公开摘要、书目信息；全文未取得 | 可支持简体问卷信效度研究简介；不证明 App 有效、训练有效或统一康复阈值。 |
| [RLE 嗓音女性化练习](https://rle.wiki/others/voice-feminisation-exercise/) | 导言及正文；社区经验结合文献的教程 | 可作中文学习体验与练习线索；固定频率、必然损伤和时间承诺仍需独立核查。不能仅因标题含“医学研究”就按临床指南引用。 |
| [跨与多元性别档案](https://digital.transchinese.org/) | 首页、收录范围与声明；混合来源档案馆 | 用于追溯原始资料。站点自述可能收录未经核实和错误内容，引用须落到具体作品。 |
| [CNTT](https://voice.cntt.uk/) | 公开介绍页；社区教程与训练服务 | 可作为中文外部资源；公开页面也有固定音区、进程及安全效果的强承诺，不能原样视为证据结论。完整教材未审。 |
| [Vocal Congruence Project](https://vocalcongruence.org/) | 专业人员制作的患者教育资源，可见站点正文 | 适合目标探索、独立练习、寻求支持与手术信息。引用实际资源标题；与疗效研究分开。 |
| [TransNavi](https://transnavi.jp/en/voice/) | 嗓音训练入门导读 | 适合简短练习原则、目标与资源导航。英文页面存在不自然表达，中文应独立编辑；不能补写它没有的“Larynx Anchoring”等专文标题。 |
| [Sheffield Trans Voice Café](https://sites.google.com/sheffield.ac.uk/transvoiceandcommunicationcafe/voice-information-resources) | 高校资源索引和可见说明；部分附件未逐项读取 | 有音高、共鸣、声音重量、护嗓与日常迁移材料。应链接并核对具体课件/工作表，不能把资源页视作所有机制与剂量的出处。 |
| [TruVox](https://ceas5.uc.edu/transvoice) | 通过浏览器查看应用的 Help/Suggestions，及大学项目资料 | 适合解释生物反馈和练习设计；Help 说明是原型、主要面向美式英语、并非完整训练方案。不能替中文语料或 Pitchee 规则背书。 |
| [ASHA Practice Portal](https://www.asha.org/practice-portal/professional-issues/gender-affirming-voice-and-communication/) | 专业实践综述 | 适合以个人目标为中心、多维评估和专业转介等原则。具体治疗研究要追到原论文；页面未为 Pitchee 的模型、分数或安全封顶作验证。 |

## 中文质量与风格

现稿常把科普、医学诊断、激励口号和算法解释混在同一段落。诸如“科学铁律”“灾难性”“彻底”“绝对”“爆发最大能量”“精准自察”的词语增强了确定感，却没有相应证据。反复使用“伪声”“卡通音”“幼态女性化”“杜绝娇柔拖沓”“成熟男性的沉稳感”，还把个体风格差异写成缺点。

建议采用平实、尊重自主选择的声音训练文风：

1. 标题说明读者可以理解或尝试什么。将“拯救机械音”“突破59分瓶颈”改为“理解音高变化”“如何理解本次评分限制”。
2. 将观察、解释、建议分开写。观察写“这次没有估计出平均基频”；解释列出可能影响因素；建议给可操作的检查。不给未经检查的生理诊断。
3. 少用“正常/异常”“正确/错误”给表达风格打标签。用“更接近你选择的目标”“听起来更明亮/低沉”“说话是否更轻松”。
4. 术语首次出现时用一句话解释。F0、共振峰、声道共鸣、声音重量、音质、响度各自定义；不以英文括号和生理名词增加权威感。
5. 涉及普通话时保留声调与语义。不要要求全部句尾下降、强调时固定在单一 Hz，或用英语句调刻板印象判断“男性/女性是否合格”。
6. 练习给起点、动作、可观察反馈、停止条件和下一步；示例时长可调整，不许诺“永久自动化”“全天不疲劳”。
7. 统一参考标题为“依据与延伸阅读”，标出“研究”“专业指南”“患者教育”“社区经验”“产品说明”。未完成临床审校前不宣称“权威循证专业教程”。
8. 按阅读任务设计结构。问卷和就医文章不必硬套“声学机制—症状排查—训练动作”四段模板；可分别使用“用途—如何理解—局限—寻求支持”等更合适的章节。

## 三个可直接采用的改写示例

### 自然度偏低

> 自然度是模型对这段录音的估计结果，会受到录音条件、说话方式和模型适用范围的影响。它不能判断声带是否受伤，也不能说明某块肌肉是否紧张。先确认录音环境，并回听声音是否符合你的目标；如果说话出现疼痛、明显费力或持续嘶哑，暂停练习并寻求专业评估。

### B 录音分数下降

> 同一句话重录后，分数可能上升或下降。一次差异不足以判断进步，也不能证明某种动作已经练对。先确认两次录音的距离、环境和读法是否相近，再回听你想改变的那个方面，并记录说话是否更轻松。出现不适时停止；暂时听不出差别也可以记为“无法判断”。

### 多元声音探索

> 非二元或中性的声音没有统一的音高标准。你可以从喜欢的声音特征出发，分别探索音高、明亮程度、轻重感和语调，再观察它们在日常交流中是否舒适、实用。频率读数可以帮助记录变化，不负责定义你的性别，也不保证他人会怎样理解你的声音。

## 修订顺序与验收

1. 优先移除或重写健康处置、TWVQ 阈值、强制手术前提、由模型诊断病理，以及以降分保证学习有效的段落。健康相关文本应由具有嗓音经验的耳鼻喉/言语语言专业人员复核。
2. 逐篇补齐证据，将无法直接支持的百分比、月份、剂量和效果承诺删除或明确改为示例。保留作者、原题和版本，不为首页编造篇名。
3. 将软件规则说明和训练正文分开组织。算法篇标明规则版本，核心训练篇以用户目标与舒适度组织；分数只作辅助信息。
4. 同步修订[推荐说明](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/VoiceTrainingLibrary.swift:374)：当前第 401/416 行把自然度低解释为挤喉或“健康保护”，第 513 行把降分解释为打破代偿，第 438 行把多元声音限定在 145–165 Hz。只改文章会让入口继续显示相同误导。
5. 从经审校的同一份 Markdown 重新生成文章仓库和 App 的 JSON。验证全部 ID、内容一致性、参考链接及展示；构建通过只能证明数据可用，不能替代内容审校。

下方清单按每篇最需要处理的问题汇总；详细理由、更多位置与来源见附录。P1 表示可能影响健康行为、就医或重大判断的错误，P2 表示实质性准确性/证据问题，P3 表示编辑表达问题。每篇的等级取本次已记录问题中的最高等级，不是对其全部内容的评分。

## 49 篇覆盖清单

按每篇最高问题等级统计：P1 26 篇，P2 23 篇。所有文章都有实质性修订项；同类问题在多篇中重复出现。

| 文章（点击定位） | 最高优先级 | 首要修订事项 |
| --- | --- | --- |
| [RULE-CONTINUOUS-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-CONTINUOUS-01-连续评分逻辑与各指标协同进展.md:16) | P2 | 将软件权重解释成人类感知贡献率；补变量定义及规则版本。 |
| [RULE-F0-UNAVAILABLE-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-F0-UNAVAILABLE-01-告别耳语-为什么系统检不出基频.md:22) | P1 | 未检出基频不等于耳语或闭合不全；删耳语必致损伤及枕头消音保证。 |
| [RULE-F0-UNAVAILABLE-02](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-F0-UNAVAILABLE-02-从气流到实声-声门闭合与发声起始.md:32) | P1 | 持续发声秒数和手背气流不能诊断声门裂隙；删100%闭合保证。 |
| [RULE-HIGH-F0-MALE-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-HIGH-F0-MALE-01-突破59分瓶颈-声道体型感与共鸣对齐.md:16) | P2 | VFP不能反推声道尺寸；删固定喉头位移和必然提分。 |
| [RULE-HIGH-F0-MALE-02](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-HIGH-F0-MALE-02-口咽腔形变与元音变色提亮.md:14) | P2 | 修正/u/元音分类；不要求所有元音保持/i/舌位。 |
| [RULE-HIGH-F0-MALE-03](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-HIGH-F0-MALE-03-摆脱卡通音-声带重量与共鸣平衡.md:12) | P2 | 声音重量/大小是感知框架；删固定喉位、挤压对照和长期安全保证。 |
| [RULE-HIGH-F0-STYLIZED-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-HIGH-F0-STYLIZED-01-告别挤卡-打破30分封顶.md:11) | P1 | 30分封顶不能检测CQ、微扰或预防声带小结。 |
| [RULE-HIGH-F0-STYLIZED-02](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-HIGH-F0-STYLIZED-02-SOVTE半封闭声道与吸管吹唇发声.md:14) | P2 | SOVT不能保证消除代偿；吹唇中断不能直接推断喉部锁紧。 |
| [RULE-HIGH-F0-STYLIZED-03](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-HIGH-F0-STYLIZED-03-声带边缘振动-从M2假声到轻质M1.md:13) | P1 | M1/M2不对应健康/病理；不能靠200Hz响度测试和模型分数判断。 |
| [RULE-LOW-F0-NATURAL-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-LOW-F0-NATURAL-01-松弛不挤喉-安全提升基频滑音阶.md:4) | P2 | 自然度高不能担保健康；删1–2周必达音区的承诺。 |
| [RULE-LOW-F0-NATURAL-02](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-LOW-F0-NATURAL-02-中性音区应用-基频不硬飙的女性化补偿.md:14) | P1 | 删固定感知贡献率与95%识别承诺；70–80分说法与59分封顶冲突。 |
| [RULE-LOW-F0-STYLIZED-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-LOW-F0-STYLIZED-01-排查20分卡点-下压喉结与气道受阻解绑.md:12) | P1 | 20分是产品上限，不能诊断MTD、气道受阻或组织损伤。 |
| [RULE-LOW-F0-STYLIZED-02](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-LOW-F0-STYLIZED-02-打哈欠叹气法与外喉肌松绑.md:42) | P1 | 删自行捏揉、晃动喉部及以难晃动判断痉挛的操作。 |
| [RULE-PASS-BOOST-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-PASS-BOOST-01-协同突破与长篇拓展.md:11) | P1 | 协同加分不能证明安全、闭合良好或特定共振峰变化。 |
| [RULE-PASS-BOOST-02](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-PASS-BOOST-02-生活实战与动态情绪保持.md:26) | P1 | 不要为维持声线固定喉头或改变必要的保护性咳嗽；删“原形毕露”。 |
| [SCORE-ADVANCED-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-02-Score-Ranges/SCORE-ADVANCED-01-从80分到90分-消除播音腔与假面感.md:14) | P2 | 审美风格不等于有害机制；删5分钟伤害阈值和真假声音等级。 |
| [SCORE-ADVANCED-02](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-02-Score-Ranges/SCORE-ADVANCED-02-语速韵律-让声音灵动流淌的停顿艺术.md:12) | P2 | 语速快不等于声门失控或频率混叠；固定语速不应作达标线。 |
| [SCORE-MASTER-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-02-Score-Ranges/SCORE-MASTER-01-90分选手终极挑战-全天候生活自动化.md:17) | P1 | 单次高分不能证明生理潜力或排除发声问题；删固定神经学习月份。 |
| [SCORE-MASTER-02](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-02-Score-Ranges/SCORE-MASTER-02-长期嗓音卫生与反流预防保嗓守则.md:25) | P1 | 晨起嘶哑不能自行确诊反流；删药后加倍饮水与蒸汽疗效承诺。 |
| [SCORE-MID-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-02-Score-Ranges/SCORE-MID-01-从60分到75分-喉腔记忆与自我监控回路.md:25) | P1 | 胸部振动消失不是正确共鸣证明；避免预先要求用户自评“更接近目标”。 |
| [SCORE-MID-02](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-02-Score-Ranges/SCORE-MID-02-练习排期-每日15分钟高效微练习节奏.md:13) | P1 | 删20/30/45分钟损伤倒计时；15分钟日程仅可作可调整示例。 |
| [SCORE-STARTER-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-02-Score-Ranges/SCORE-STARTER-01-面对50分以下-拆解声学生理微习惯.md:22) | P1 | 触摸和气流不能诊断MTD/闭合不全；删固定三周通关。 |
| [SCORE-STARTER-02](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-02-Score-Ranges/SCORE-STARTER-02-心理调适-嗓音性别焦虑自护与客观解耦.md:12) | P2 | 不把声音焦虑归为确定脑区误判或肌群痉挛；尊重实际社会压力。 |
| [METRIC-DURATION-SHORT-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-DURATION-SHORT-01-气息支撑-胸腹联合呼吸与慢呼气训练.md:28) | P1 | 吸气性喉鸣不是浅呼吸训练问题；短录音不等于气息或闭合缺陷。 |
| [METRIC-NATURAL-LOW-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-NATURAL-LOW-01-自然度重构-声带过度撞击与声门漏气消除.md:12) | P1 | 模型分数不能分型声门裂隙/室褶挤压；SOVT不保证后声门闭合。 |
| [METRIC-NATURAL-TENSION-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-NATURAL-TENSION-01-喉外肌过度活动综合征MTD排查.md:13) | P1 | “命中两条”不是MTD诊断；固定禁声和热敷排乳酸无充分依据。 |
| [METRIC-PITCH-HIGH-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-PITCH-HIGH-01-避免过犹不及-寻找黄金频段190-220Hz.md:16) | P1 | 260Hz不是环甲肌普遍物理极限；删除黄金音区和安全上限。 |
| [METRIC-PITCH-MONOTONE-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-PITCH-MONOTONE-01-语调起伏-拯救机械音与上升语调.md:16) | P2 | 修正半上声；连续言语标准差不能定义情感或性别。 |
| [METRIC-PITCH-UNSTABLE-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-PITCH-UNSTABLE-01-音准稳定-腹式呼吸与声带张力微调.md:3) | P2 | F0标准差不同于Jitter；保留汉语词调并排除追踪错误。 |
| [METRIC-VFP-DARK-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-VFP-DARK-01-共鸣提亮-舌背隆起与咽腔缩小实战.md:5) | P2 | VFP不等于R1；删固定共振峰处方与持续高舌位要求。 |
| [METRIC-VFP-NASAL-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-VFP-NASAL-01-告别夹鼻音-软腭升降与真共鸣辨析.md:3) | P2 | 区分鼻音过重/过轻；捏鼻例句含大量鼻韵尾，不能作所述自诊。 |
| [METRIC-VFP-THIN-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-VFP-THIN-01-充实音色-防止单薄如纸与声门闭合抗阻.md:15) | P1 | 听感不能测得CQ或诊断闭合无力；数字电平不代表声带力量。 |
| [METRIC-VOLUME-PROJECTION-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-VOLUME-PROJECTION-01-声音投射力-不挤喉咙的前提下增强响度.md:30) | P1 | 低电平不能定位声道能量损失；先检查设备，再探索舒适响度。 |
| [MASCULINE-BASICS-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-04-Masculine-Voice/MASCULINE-BASICS-01-男性向嗓音基础-扩大声道与胸腔共鸣协同.md:12) | P2 | 不将最低喉位与胸骨强振动当成功标准；气泡音不自动等于损伤。 |
| [MASCULINE-INTONATION-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-04-Masculine-Voice/MASCULINE-INTONATION-01-男性语调特征-平稳沉着与着重降调结构.md:14) | P2 | 删幼态/娇柔等贬义；固定基频、全部降调不适合普通话及多样目标。 |
| [MASCULINE-LARYNX-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-04-Masculine-Voice/MASCULINE-LARYNX-01-避免压喉坏嗓-松弛降低喉头的正确方法.md:16) | P2 | 删必然损伤的解剖链及晃喉自检；触感轻松不是健康保证。 |
| [MASCULINE-ON-T-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-04-Masculine-Voice/MASCULINE-ON-T-01-变声期嗓音管理-睾酮变声期间的破音与水肿防护.md:39) | P1 | 删SOVT排间质液、6分钟减少破音的承诺和固定30%增重。 |
| [MASCULINE-PRE-T-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-04-Masculine-Voice/MASCULINE-PRE-T-01-未用睾酮激素Pre-T的声音降低指南.md:5) | P2 | 删必然被识别为男性、精确毫米/共振峰承诺；避免“欺骗性”。 |
| [NONBINARY-EXPLORE-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-05-NonBinary-Exploration/NONBINARY-EXPLORE-01-中性与多元声音探索-在145-165Hz找到属于你的性别平衡.md:14) | P2 | 非二元不限定145–165Hz，也不等于目标不确定；删除潜意识归因。 |
| [NONBINARY-FLUIDITY-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-05-NonBinary-Exploration/NONBINARY-FLUIDITY-01-嗓音流动性-声线自由切换指南.md:6) | P2 | Bigender不是“双性性格”；删3秒无疲劳切换与三挡统一标准。 |
| [PRACTICE-AB-DROP-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-06-Guided-Practice-AB/PRACTICE-AB-DROP-01-AB复测得分下降-动作重塑期的正常波动.md:5) | P1 | B分下降不能证明打破代偿或形成U型学习曲线。 |
| [PRACTICE-AB-SUBJECTIVE-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-06-Guided-Practice-AB/PRACTICE-AB-SUBJECTIVE-01-自评困惑-听感更接近目标但分数没变的原因.md:27) | P1 | 分数变化不能认证健康；删1–2周自动涨分及“虚假自洽”。 |
| [PRACTICE-AB-UNSURE-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-06-Guided-Practice-AB/PRACTICE-AB-UNSURE-01-听辨训练-从听着迷茫到精准自察.md:54) | P2 | 不以更高更薄更亮作通用目标；“无法判断”和费力感需如实保留。 |
| [QUALITY-CLIPPING-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-07-Recording-Quality/QUALITY-CLIPPING-01-解决clipping削波-爆音对声学特征的破坏及防喷麦技巧.md:12) | P2 | 区分浮点范围、数字满幅、谐波失真和混叠；删固定90%改善率。 |
| [QUALITY-ENVIRONMENT-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-07-Recording-Quality/QUALITY-ENVIRONMENT-01-排查lowLevel与background-麦克风距离与信噪比指南.md:15) | P2 | VAD电平差不是严格SNR；距离、麦克风和降噪结论须限定设备。 |
| [HEALTH-CLINICAL-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-08-Health-Psychology-Clinical/HEALTH-CLINICAL-01-就医指南-何时寻求嗓音支持专家与咽喉科医生专业帮助.md:46) | P1 | 删除6–12个月强制术前训练门槛；区分急性危险与常规评估。 |
| [HEALTH-HYGIENE-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-08-Health-Psychology-Clinical/HEALTH-HYGIENE-01-嗓音卫生全书-日常护嗓水分补给与科学冷身.md:12) | P2 | 修正真声带上皮类型；删晨起禁声窗口、必须冷身等伪生理规则。 |
| [HEALTH-REDLINE-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-08-Health-Psychology-Clinical/HEALTH-REDLINE-01-安全红线-刺痛干涩与嘶哑失声的紧急处置.md:38) | P1 | 删热杯贴脸蒸汽、统一4小时禁声与次日蜂鸣放行；按症状安排就医。 |
| [HEALTH-TWVQ-01](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-08-Health-Psychology-Clinical/HEALTH-TWVQ-01-科学自评-跨性别女性嗓音问卷TWVQ-SC与生活质量量表.md:54) | P1 | 删45/75/85分诊断与心理归因；样本均值待核实，改写题项需标明。 |

## 详细附录与复核记录

- [模块 01、03：声学、算法与动作审阅](/Users/dannyfeng/Documents/Pitchee/Docs/Research-Evidence/voice-training-audit-2026-10-05/acoustics.md)
- [模块 04、05、08：男性向、多元探索与健康审阅](/Users/dannyfeng/Documents/Pitchee/Docs/Research-Evidence/voice-training-audit-2026-10-05/health.md)
- [模块 02、06、07：学习、A/B 与录音质量审阅](/Users/dannyfeng/Documents/Pitchee/Docs/Research-Evidence/voice-training-audit-2026-10-05/learning.md)
- [结构化问题、来源范围与文件快照](/Users/dannyfeng/Documents/Pitchee/Docs/Research-Evidence/voice-training-library-audit-2026-10-05.json)

验证方式：逐篇内容审阅、公开资料交叉核查、当前源码对照、49 篇正文与两份 JSON 的一致性检查，以及最终报告的文章覆盖和链接位置检查。本次没有更改运行代码，因此未执行 App 构建或回归测试；没有把内容检查说成临床验证。
