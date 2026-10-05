# 嗓音训练知识库审阅：Module 01 与 Module 03

审阅日期：2026-10-05。范围：Module-01-Engine-Rules 15 篇，Module-03-Acoustic-Dimensions 10 篇。已完整通读 25 篇，未修改文章或源码。优先级：P1 = 安全/核心科学误导，P2 = 重要准确性，P3 = 编辑与风格。优先级按问题评定，非按文章一刀切。

## 总体结论

25 篇均有实质性修订项，没有可以列为“无重大问题”的篇章。练习主题中有可保留的内容：轻柔哼鸣、舒适范围滑音、SOVT、逐步迁移至日常言语、避免以分数压过舒适感。但大量生理解释、精确数字、医学诊断、效果保证和引文标题不可靠，不能仅靠润色达到发布质量。最严重的是把 App 分数/录音质量当成身体诊断，给普通自学者未经评估的喉周操作，并把狭窄的音高区间定义成生理安全边界。

## 已核实的代码事实

- [analyzer.cpp](/Users/dannyfeng/Documents/Pitchee/Dependencies/PitcheeCore/src/analyzer.cpp:335)：335–368 将 normalized embeddings 的均值与标准差拼成特征；530–548 使用与 VFP 同一窗口集；637 将特征送入自然度模型。[naturalness.cpp](/Users/dannyfeng/Documents/Pitchee/Dependencies/PitcheeCore/src/naturalness.cpp:16)：输入 384 维、输出 0–100 分。接口没有提供 CQ、Jitter、Shimmer、HNR、声门裂隙、室褶活动或病变检测结果。不能仅凭此宣称学习特征完全不包含相关信息，但更不能把未验证的模型分数解释成这些指标或临床诊断。
- [analyzer.cpp](/Users/dannyfeng/Documents/Pitchee/Dependencies/PitcheeCore/src/analyzer.cpp:553)：553–561 的 VFP 是分类窗口概率均值 ×100，并非直接测得声道长、咽腔体积、F1 或 R1。
- [scoring.cpp](/Users/dannyfeng/Documents/Pitchee/Dependencies/PitcheeCore/src/scoring.cpp:44)：无 F0 回退 VFP；51–65 的女性公式与 RULE-CONTINUOUS 主要系数相符；69–98 的规则阈值与多数文章场景相符。但 cap 是上限，不保证达到该分数；pass_boost 命中不保证 score_boosted 为 true。86–89 明确 <=165 Hz 且自然度 >=50 时 cap=59，故此音区不能得 70–80 分。
- [analyzer.cpp](/Users/dannyfeng/Documents/Pitchee/Dependencies/PitcheeCore/src/analyzer.cpp:143)：有效 F0 还要求置信度 >0.9 且 75–600 Hz；未检出并不能归因为耳语或声门未闭合。
- [PracticeData.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeData.swift:71)：71–72 明确 quality checks 是临时录音启发式、非临床判断；87–95 是 speechSeconds <5、speechDBFS <-45、语音与背景差值 <10 dB、clippedFraction >=0.01。文章中的 12 dB 不是当前代码阈值。
- [RecordingStatistics.swift](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingStatistics.swift:40)：165/255 等频段只描述频率，代码特意注明不表示身份；137–142 的 dBFS 是数字录音 RMS 幅度，未校准为声压级，更不是生理能量损失。

## 支持判断的主要来源

- S1：[ASHA — Gender Affirming Voice and Communication](https://www.asha.org/practice-portal/professional-issues/gender-affirming-voice-and-communication/)。已读：强调个人目标、舒适与安全；综合 pitch/resonance 等；不能过度关注 SFF；顺性别女性也有多样声音配置。给出的 180/130 Hz 或 145–175 Hz 是文献中的感知/分布参考，不是临床安全阈值。
- S2：[ASHA — Voice Disorders](https://www.asha.org/practice-portal/clinical-topics/voice-disorders/)。已读：听感不能单独确定疾病严重程度/原因；综合评估和必要仪器检查；manual circumlaryngeal techniques 属于临床治疗，实施需小心；手前气流是 flow phonation 的反馈手段，不是解剖诊断；SOVT、共鸣治疗可用，但不能承诺必然闭合/疗效。
- S3：[ASHA — Resonance Disorders](https://www.asha.org/practice-portal/clinical-topics/resonance-disorders/)。已读：hypernasality 与 hyponasality 不同；感冒、过敏性鼻炎与阻塞常导致 hyponasality；正常鼻音和协同发音的鼻化不应全消除。
- S4：[Laryngeal Hyperfunction During Whispering: Reality or Myth?](https://pubmed.ncbi.nlm.nih.gov/16503476/)。检索到原始研究摘要：100 名嗓音门诊患者中 69% 耳语时上喉部挤压增多，13% 减少，18% 无明显变化。支持“用力耳语可增加紧张”，不支持“所有耳语最伤嗓/必致结节/摧毁肌肉记忆”。[NIDCD 护嗓页](https://www.nidcd.nih.gov/health/taking-care-your-voice)确实建议避免极端发声和耳语，因此不应反向写成耳语绝对安全。
- S5：[Kapsner-Smith et al., 2015，SOVT 随机试验](https://pmc.ncbi.nlm.nih.gov/articles/PMC4610291/)。存在疗效证据，但样本、练习方案、口径和阻力均有关；不支持自动“100% 闭合”或保证 App 提分。[Maxfield et al. 的压力研究](https://pubmed.ncbi.nlm.nih.gov/24865621/)亦说明不同动作压力不同。
- S6：[Roubeau, Henrich & Castellengo, 2009](https://pubmed.ncbi.nlm.nih.gov/18538982/)及[作者提供论文](https://www.lam.jussieu.fr/Membres/Castellengo/publications/2009a-Vocal-Registers-revisited_Engl.pdf)。M1/M2 为振动机制且有音高重叠，不能靠 200 Hz 放大音量或 App 自然度自诊断；M2 不等于假/不健康/必漏气。
- S7：[IPA 官方交互元音表](https://www.internationalphoneticassociation.org/IPAcharts/IPA_charts_TI/IPA_charts_TI.html)。/u/ 为后高圆唇元音，非后低元音；元音分类须考虑舌位与唇形。
- S8：[Joliveau, Smith & Wolfe, Nature 2004](https://www.nature.com/articles/427116a)；[Weiss et al., Singer's formant in sopranos](https://pubmed.ncbi.nlm.nih.gov/11792022/)。女高音高音区常用最低声道共振与 F0 对齐，不能把整个投射能力归结为 3000 Hz 歌手共振峰。
- S9：[RLE 文档入口](https://rle.wiki/others/voice-feminisation-exercise/)与[voice.cntt.uk](https://voice.cntt.uk/)。前者明确作者为 Catherina Grace 等、依据个人体验汇总且站点提示可能过时/不准；后者为自学文稿及训练服务页。两者属于社区教学资源，不能给文章中的精确生理数字或疗效保证赋予临床证据等级。本文不将其所有具体练习全盘判错。

## 逐篇覆盖与具体问题

### 1. RULE-CONTINUOUS-01 — P2

文件：[连续评分逻辑与各指标协同进展](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-CONTINUOUS-01-连续评分逻辑与各指标协同进展.md:12)

- 16–18：“权重高达 50%…这印证了声学事实”。模型设计权重不能反过来证明人类感知的生物学贡献率。改成“这是当前版本的产品评分设计，不能作为性别感知或训练优先级的通用比例”。
- 35：“VFP 越低，说明声道越宽阔雄浑”。模型概率不能测声道形状。改成“该模型的此方向评分更低”，必要时解释模型用途和限制。
- 13 的公式正确但未定义 S_r/N_r；应补 `S_r=VFP/100, N_r=clamp((N-40)/50,0,1)`，并说明是特定 profile 和版本。
- 43–45 鼓励优先追 VFP、以低自然度作为生理底线。建议训练优先级由个人目标/舒适度/听感确定，阈值仅解释分数变化。
- 54 的 ASHA 引用标题不是已打开页面的真实标题；改为真实题名、章节和直接支持的主张。

### 2. RULE-F0-UNAVAILABLE-01 — P1

文件：[告别耳语](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-F0-UNAVAILABLE-01-告别耳语-为什么系统检不出基频.md:12)

- 22–25：“耳语是对声带最残酷的摧残之一”“会厌软骨向后翻折…结节风险”“彻底摧毁发声肌肉记忆”。严重夸大且把多种耳语形态写成必然病理。用 S4 改为“用力耳语可能增加喉部紧张，不宜把耳语当成保护嗓音的保证；轻声和休息方式需按情境选择”。删除剪切应力、结节和记忆摧毁的确定性描述。
- 5、15 将未检出 F0 归结为声门未闭合/严重嘶哑、置信度 <0.9。应先检查录音音量、距离、噪声、语音长度和模型有效范围；不由结果诊断闭合。
- 34–37：“30 厘米的人也完全听不到”“瞬间捕获…精准”。与低电平警告冲突，无听觉/设备保证。改为“舒适轻声、能被麦克风清楚记录”。闭唇哼鸣与朗读是两个不同任务，须明确过渡。
- 40–41：“将脸埋入…抱枕或厚毛巾”“吸收 80% 以上”。删除无来源定量；不要以覆盖口鼻为常规方案，改选择合适空间、时间及与口鼻留距离的软装隔音。
- 13 的伯努利+肌张力过于简化，可简单写肌弹性—气动机制；14 的湍流不应等同理想白噪声。
- 47–48 的书籍副标题/项目文章题名无法由当前链接核实，不能作为上述机制的已证实引用。

### 3. RULE-F0-UNAVAILABLE-02 — P1

文件：[声门闭合与发声起始](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-F0-UNAVAILABLE-02-从气流到实声-声门闭合与发声起始.md:27)

- 32–33、54–55：“单音…小于 5 秒，说明声门后部…闭合漏气缝隙”“3 秒…说明…间隙过大”。手背气流和最大持续发声时间受肺功能、任务、音高、音量、努力程度等影响，不能定位声门后部。改为非诊断观察，反复异常或声音症状交专业评估；使用 S2。
- 50：“嘴唇分担…毫无压力…100% 紧密接触”。/v/ 练习不能保证百分之百闭合，完全闭合也不是所有健康发声的唯一标准。改为“可能帮助找到较省力的气流—发声配合”。
- 20–21：“同一千分之一秒”“既不漏气，也不撞击”。无依据的精确时间，正常振动本可发生接触，协调起音也不保证整句闭合。删除绝对化机制。
- 35 重复耳语损伤恐吓。47–48 的 /v/ 是上齿轻触下唇，不宜让读者咬唇。

### 4. RULE-HIGH-F0-MALE-01 — P2（含练习边界）

文件：[声道体型感与共鸣对齐](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-HIGH-F0-MALE-01-突破59分瓶颈-声道体型感与共鸣对齐.md:16)

- 16–20 将 F1、声道尺寸、二元性别、模型 cap 与“成年人巨人学儿童”直接相连。F1 随元音舌高显著变化，不是独立体型测量；声道平均长度只可作群体说明，不能由 VFP 反推个人解剖。
- 28：“喉头上抬 1 厘米…整体共鸣频率显著拉高”。均匀管近似不能作为个体运动量处方。删除厘米目标，强调轻松探索，不固定喉头或挤咽部。
- 39、43：“全球…公认…最安全”“VFP 将直接突破 70”。社区练习非已验证通用安全法，更无提分保证。改为可选听觉探索、短暂自然气流、出现不适即停，去保证数字。
- 46–49 “无声练习 = 声门零张力零摩擦”不成立。无声不保证不费力；不能作为损伤风险的证明。
- 4、20 的“男生在尖叫”“巨人捏嗓学儿童”有羞辱效应，应换为可描述的声音特征。

### 5. RULE-HIGH-F0-MALE-02 — P2

文件：[口咽腔形变与元音变色](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-HIGH-F0-MALE-02-口咽腔形变与元音变色提亮.md:12)

- 14：“/u/ 与 /a/：后低元音…共振峰整体偏低”。/u/ 是后高圆唇元音；/a/ 不是可一概归为后元音，且开元音 F1 通常更高。用 S7 修正，不把所有峰值概括为一起变低。
- 12：“完全取决于舌位”。缺唇形、下颌、声道长度等；16、29–36 要求所有元音保留 /i/ 高舌位，会破坏元音区分与清晰度。改成在保持元音可辨的前提下做小幅探索。
- 31 的“下颌微张 2 毫米”、50 的牙距给人虚假的通用运动标准，删除定量处方。
- 26 的面罩振动是感觉线索，不能证实共振峰或精确能量位置。

### 6. RULE-HIGH-F0-MALE-03 — P2

文件：[声带重量与共鸣平衡](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-HIGH-F0-MALE-03-摆脱卡通音-声带重量与共鸣平衡.md:12)

- 12–23：“嗓音科学界普遍采用两个正交维度”“咽腔容积承受不了…爆发能量”。Size/Weight 是有用的部分社区教学框架，非已确立排他二维模型；“容积承受不了能量”不是这种听感的科学机制。改为可供比较的感知描述，不等同解剖或健康。
- 5 同时把轻+小列为失衡，21 又列为理想，术语内部不一致。
- 38 的“喉头…0.5–1 cm”缺乏个体化依据；49 让 A 轮“刻意挤小”，不宜要求复现紧张动作作对照，改对照两种舒适尝试。
- 51：“自然度上升 10 分…真实长久自如声线”。一个模型差值不能证明长期适应/安全；改看重复录音、舒适度、听感和日常可用性。
- 1、18–23 的米老鼠、空心巨人、男性厚 M1 等固定标签应重写。

### 7. RULE-HIGH-F0-STYLIZED-01 — P1

文件：[告别挤卡与30分封顶](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-HIGH-F0-STYLIZED-01-告别挤卡-打破30分封顶.md:11)

- 11–18 把模型解释为 CQ 40%–50%、Jitter/Shimmer 健康值检测，并声称封顶可避免“不可逆的声带小结与 MTD”。源码不输出这些指标，也没有此处所称临床验证；小结/MTD 更非一概不可逆。必须重写为评分说明，安全提醒依据真实症状，不能以高分担保健康或低分诊断。
- 14 的“TA 与 CT 强烈冲突→下咽缩肌夹紧室褶”是确定性错误机制链，肌肉协同和声道活动不能这样推断。
- 39、44：“每块肌肉彻底松解”“第一次…无压力纯净高音”；51：“自然度重返70”。去所有必然效果。
- 43 对已经挤卡人群直接安排“高音段”滑音，改为个人舒适范围并规定停练条件。无须精确控制舌骨/声带。

### 8. RULE-HIGH-F0-STYLIZED-02 — P2

文件：[SOVTE 吸管与吹唇](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-HIGH-F0-STYLIZED-02-SOVTE半封闭声道与吸管吹唇发声.md:12)

- 14–16：“反压推开声带”“彻底阻断喉外肌代偿”“自动理想状态”。SOVT 的声源—声道相互作用、平均压力和声学阻抗较复杂，不能保证消除发力或特定闭合；用 S5 限定效应。
- 28：“吹唇中断说明挤卡锁死…增加腹部气息”。中断也可因唇张力/气流/音高等，照此增加气压会促使过度用力。改先减弱强度、降低难度、舒适重试。
- 27 的180–200 Hz不能作每个人起点；29保证提分应删除。
- 32、34 的管径和入水深度显著影响阻力；浅水提示方向合理，但仍须舒适呼气、不吸入水、不憋气、不追求更细管/更深水，若无法轻松发声改空气中吸管或请指导。
- 可以保留 Titze 2006 文献，补 DOI/可核验直达链接；不应以“假声脱敏”命名这种通用练习。

### 9. RULE-HIGH-F0-STYLIZED-03 — P1

文件：[M2 到轻质M1](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-HIGH-F0-STYLIZED-03-声带边缘振动-从M2假声到轻质M1.md:12)

- 13–21 将 M1/M2 与性别、真假、病理做一一对应；M2 被描述成“非自然微颤”“断开阻抗”，轻 M1 = 完整闭合。S6 不支持这些归类。应说明机制与音高重叠、M2可以健康使用、感知重量不是能直接意识操控的声带厚度，别把训练设为摆脱“假声音”。
- 29–35：“200 Hz 稍放大破音说明 M2”“热风+自然度<60说明闭合不良”。这些都不能诊断振动机制、肌肉招募、出血风险或闭合。必须删除这些判定。
- 42 的“最低沉气泡音”不应作为所有人安全起点；气泡音也不应一会儿称危害、一会儿称万能激活。
- 48、55：“260 Hz 就是 M2”“不破音即掌握 M1”都不成立；改为舒适滑音/轻微响度变化观察，不命名生理机制。

### 10. RULE-LOW-F0-NATURAL-01 — P2

文件：[安全提升基频滑音阶](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-LOW-F0-NATURAL-01-松弛不挤喉-安全提升基频滑音阶.md:3)

- 4、11–16 将 naturalness>=50 等同没有代偿/健康，cap 叫“温柔保护”，不具科学依据；低音高本身也不是必须跨过的性别门槛。场景可保留数值、医学推断删除。
- 38：“每天1–2半音…1–2周自然平移至175–220”。没有适用于所有人的改善时程；改为以舒适度、恢复和任务成功决定进阶。
- 22、56 把训练说成拉皮筋/肌腱弹性适应，容易让人追求拉伸力度。应以协调和技能学习解释，承认组织/个体差异。
- 28 的社区练习不能保证无代偿；47“清辅音…天然促进声带边缘化”无论据。参考以具体文稿章节支持经验，勿当医学法则。

### 11. RULE-LOW-F0-NATURAL-02 — P1 / P2

文件：[中性音区共鸣与语调](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-LOW-F0-NATURAL-02-中性音区应用-基频不硬飙的女性化补偿.md:12)

- P1，14–18：F0 30%–35%、共鸣40%–45%、韵律20%–25%，以及155 Hz“95%以上识别女性”均无可核验证据，且跨说话人、语言、听众不可能直接套用。删除数字，改为多维线索及感知不确定性，参 S1。
- P2，42：“中性区录音可能70–80分”与当前女性 profile cap=59直接矛盾。应明示评分有上限也不代表个人声音不合目标。
- P2，24–27“共鸣极致”“全部声能集中鼻梁”“150 Hz胸骨不应振动”错误。振动感觉不能反推能量分布/共振峰；不要为消除正常触感增加紧张。
- P3，6“无懈可击”、43“全天几万字不会疲劳”不必要的效果保证；30–36 应提供风格选择，不把上扬/细腻固定为女性。

### 12. RULE-LOW-F0-STYLIZED-01 — P1

文件：[20分卡点与气道](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-LOW-F0-STYLIZED-01-排查20分卡点-下压喉结与气道受阻解绑.md:11)

- 12–16：“保护性截断”“类似MTD”“极易水肿息肉”“身体通过App求救”。模型分数不能诊断发紧、气道受阻或病变风险。改为分数含义及独立症状提醒；存在呼吸困难/明显喘鸣等不安排自练来“贯通气道”。
- 24、28 将喉头下移必然扭曲软骨、舌根后移必然盖声门，解剖机制过度简化并把正常动作病理化。
- 37–51“彻底失活”颈肌、绕环、吐舌呼吸、连续三天蜂鸣作为低分处方，没临床适应证。改为无痛小幅度肩颈舒展和舒适短声练习的可选建议，有真实疼痛或呼吸症状先评估。

### 13. RULE-LOW-F0-STYLIZED-02 — P1

文件：[打哈欠叹气与喉周按摩](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-LOW-F0-STYLIZED-02-打哈欠叹气法与外喉肌松绑.md:40)

- 42–49 给未经评估的读者按揉舌骨区、捏甲状舌骨间隙、左右晃喉头，并以“晃动费劲”判“痉挛”。临床存在手法治疗不代表适合文本自学；警告别压颈动脉不足以保证操作正确。建议移除喉部操纵教程；如保留，只说明需受训练的嗓音专业人员评估和示教，不给自诊断结论。S2 支持其临床定位。
- 5“强制热身”、6“彻底放松下咽缩肌”等过度；14 对喉外肌只描述吞咽也误导，喉位置控制不是唤醒错误肌群的二元问题。
- 23“经典循证疗法”应区分哈欠叹气和人工喉部治疗，不把组合泛化为统一有效方案；29喉位最低不等于最健康/最松弛。

### 14. RULE-PASS-BOOST-01 — P1

文件：[协同突破与长篇拓展](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-PASS-BOOST-01-协同突破与长篇拓展.md:11)

- 11–14：“pass_boost说明安全女性化频段”“模型没检测假嗓/挤捏/漏气”“声门闭合良好”“F1整体上移”。全部是未经验证的生理/健康担保，必须重写成算法命中阈值，不论分数多少都以实际不适为准。
- 26“回气仅半肺”、35“摸到胸骨振动说明共鸣掉落”缺乏根据。改自然换气，触感仅作为个人线索而非判断。
- 34 句尾统一平收/微扬会干预普通话调型和语用，改为可选个人表达练习。
- 41“不可在疲劳状态下大声朗读超过20分钟”容易被读成前20分钟可继续；应出现疲劳就暂停，不设置带疲劳用声配额。

### 15. RULE-PASS-BOOST-02 — P1 / P3

文件：[生活实战与动态情绪](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-01-Engine-Rules/RULE-PASS-BOOST-02-生活实战与动态情绪保持.md:11)

- P1，12–14：反射必然把喉头“砸回最低位”、气流使深胸共鸣、声带边缘被“击碎”等无可信机制，应改自然言语与非言语发声可能不同，练习是探索选择。
- P1，26“手扶喉头确保上抬微悬”、32叹息160 Hz戛然而止、38“需要咳嗽改高音短促轻咳”。不应要求维持固定喉位，更不应为了性别听感普遍改造必要的保护性咳嗽。删除咳嗽调音教程；区分无效习惯性清嗓与真正需要清除分泌物/异物的咳嗽，反复咳嗽应评估病因。
- P3，3–5：“原形毕露”“暴露真实生理音色的破绽”“驯化”。直接损害性别肯定，暗示当前表达是伪装。改“不同情境下声音变化”“希望保持或探索的表达”；笑声不是必须女性化的测试。

### 16. METRIC-DURATION-SHORT-01 — P1

文件：[气息支撑与慢呼气](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-DURATION-SHORT-01-气息支撑-胸腹联合呼吸与慢呼气训练.md:25)

- 28 将“吸气喘鸣 Stridor”归为高位浅呼吸/仅充盈30%，属于危险误导。吸气性喉鸣可涉及气道问题，不能据此安排撑气练习；应删除错误归因并给及时医疗评估提示，有明显呼吸困难应急处置。
- 3–5、14–19、31 将短录音/手背气流诊断为闭合漏气、肺利用低。shortSpeech 是有效语音录制量，可以另读一句并自然换气，不是单次最大呼气时长测验。将录音排查与气息困难拆开。
- 13 的15%–20%、28的30%、44的15秒及格/25–30秒进阶缺数据和适用人群。删除通用达标数字，避免憋气竞赛。
- 49–53 标题胸腹联合呼吸但要求胸口完全不上抬，错误地排斥正常胸廓运动。改胸腹自然协同、勿强吸过满或刻意固定胸廓。

### 17. METRIC-NATURAL-LOW-01 — P1

文件：[自然度重构](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-NATURAL-LOW-01-自然度重构-声带过度撞击与声门漏气消除.md:12)

- 12–18、26–32 为不同 naturalness 区间指定 HNR、Jitter/Shimmer、后声门裂隙、室褶挤压病理，代码和临床证据均不能支持；修改为“模型评价低，需要先排查录音再结合感受，不能判断具体发声病因”。
- 17 把硬起音与 Vocal Fry 当同义词，二者不是同一现象；微扰也不等于整个句子宏观音高起伏。
- 40：“SOVTE物理倒逼…软骨间部闭合”。错误保证；44“大口下巴画圈强制打碎静态痉挛”是危险的治疗语气，改为专业指导下可选、轻松小幅度，不给已患病推断。
- 27 的 /a/ <8秒同样不能定位闭合问题。

### 18. METRIC-NATURAL-TENSION-01 — P1

文件：[MTD 自我排查](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-NATURAL-TENSION-01-喉外肌过度活动综合征MTD排查.md:12)

- 13 将所有 MTD 限为无器质病变，漏掉继发性肌紧张；15“发生率最高头号职业病”、17“命中2条”缺数据/验证。不能作为自我诊断量表。
- 27–34 统一“强制48–72h禁声”、舒适“低原声”、40–42℃热敷排“乳酸”解除深部痉挛，没有支持。改停止诱发不适动作、减少用声并按症状评估；舒适音高不是强制低原声，热敷最多可描述为可能缓解表浅肌肉不适，不是治疗病因。
- 37：“无声笑通过迷走反射强力外展室褶”无可核验机制，不能用来保证气道打开。
- 52“一周后仍有疼痛才就诊”不应作为所有人等待标准；本篇包含吞咽问题、失声、所谓窒息，需区分应尽快评估与急症，不让用户先自我理疗满一周。
- 53 SLP 评估与本地医生进行喉镜的职责应准确表达；不是所有情况必须“频闪”才可评估。

### 19. METRIC-PITCH-HIGH-01 — P1

文件：[所谓黄金190–220Hz](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-PITCH-HIGH-01-避免过犹不及-寻找黄金频段190-220Hz.md:12)

- 16–19：“260Hz以上CT过度拉伸物理极限…黏膜波消失…动态归零”。明确错误；260 Hz 远非人类普遍生理极限，F0不能独立判断损伤。属于最应删除的核心科学误导。
- 14–15、28、42–44：“全球常模180–230”“240–260极少且幼儿化”“A3舒适上限”“208–220绝大多数跨女理想”。把统计/产品频段改成统一处方，且缺语言、年龄、任务和样本；改成个体舒适范围，非黄金普适频段，参S1。
- 30–31 用自摸位置诊断 CT/咽缩肌超负荷不可靠；有疼痛/吞咽困难应停止诱发并评估。
- 47 要求先复现习惯“尖刺高音”不必要；50端庄/可信赖、19引人侧目等风格判断不应包装为科学。

### 20. METRIC-PITCH-MONOTONE-01 — P2

文件：[语调起伏](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-PITCH-MONOTONE-01-语调起伏-拯救机械音与上升语调.md:12)

- 16：“女性平均一倍以上音高动态范围”，未说明Hz/半音及语言、任务、证据；相同半音变化在高基频产生更大Hz差，不能把绝对Hz倍数当表达差异。
- 25：“SD<12Hz缺乏人类情感起伏”无通用阈值，且适用场景写<10Hz。应说明文本、声调、时长影响，推荐相同材料对比而非病理/情感诊断。
- 43 把“前半微降、后半迅速抬升”叫半上声，语音学错误：非句末常见半上声是低降/低平而不实现完整后升；上声变调另论。165Hz“安全底线”不存在，44截断第四声亦可能改变字调。
- 29–33、62 把正常低落点/句尾降调归为生理代偿。要区分汉语词汇声调与句调，允许目标声线正常变化。
- 5、14–17、59–62的亲和女性/威权男性二分应改为个人风格选择。

### 21. METRIC-PITCH-UNSTABLE-01 — P2

文件：[音准稳定](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-PITCH-UNSTABLE-01-音准稳定-腹式呼吸与声带张力微调.md:3)

- 3–5 将整段 SD>35Hz、Jitter、破音和气息不稳混同。连续普通话的SD可能只是正常词调、语调，Jitter是周期微扰；也需排除倍频/半频追踪错误。先分任务，再区分刻意变化、非自愿抖动和分析错误。
- 13：“每1cmH2O→2–5Hz”至多是特定条件研究量级，不是个人通用物理定律；气流和压力量混用。可改方向性说明“气压可影响F0，幅度因人和发声条件而异”。
- 38–41“厚书重压”“胸腔肩膀完全静止”不适合通用示范；用手轻感腹部，允许胸廓自然运动，勿强压。
- 50–51 长句固定一个音高会与上一篇正常语调训练冲突。持续元音用于观察相对稳定性，连续言语则保留自然声调与语调。

### 22. METRIC-VFP-DARK-01 — P2

文件：[舌背隆起与咽腔缩小](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-VFP-DARK-01-共鸣提亮-舌背隆起与咽腔缩小实战.md:5)

- 5–6：“F1至270–300、F2/F3至2200–2800”。/i/通常低F1高F2这个方向可保留；F3并非和F2共享一段固定数值，个体/语音样本不同，不能通用处方。
- 15、25、28 将舌根触感、咽腔几何、VFP/R1相等，且声道面积变化复杂不能单向推断。明确VFP不是R1，触诊无法确认舌根/会厌位置。
- 30–41 强求/a/o也保持/i/高舌背和“贴紧磨牙”，会损害清晰度或造成过度用力。可探索轻微变化，保留可辨元音，无需持续固定舌形。
- 44–47“假咽音”与向内收拢触觉需要非常清楚的边界，避免教读者挤窄喉咙；若无可靠示教可删除此动作。
- 27“身高两米的人假扮尖细”及42“奇迹质变”改中性听感描述。

### 23. METRIC-VFP-NASAL-01 — P2

文件：[鼻音与软腭](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-VFP-NASAL-01-告别夹鼻音-软腭升降与真共鸣辨析.md:3)

- 3、15–19把“感冒堵鼻音”当 hypernasality，把“真实女性共鸣”定义成100%口腔、完全切鼻。S3明确鼻音过重/过轻不同；正常鼻辅音和协同鼻化不可消除。中文应叫“腭咽闭合”，非口咽闭锁。
- 26要求避开m/n，却给“今天天气很晴朗，万里无云”：今、天、很、晴、朗、万、云均含鼻韵尾，朗也有 /ŋ/。捏鼻必改变正常鼻音，造成大量假阳性。改无鼻音的短元音/合适语料，仅作对比不能诊断。
- 29–30 “任何丝毫变化”判疾病标准过严。捏鼻反馈不能替代腭咽检查，尤其鼻阻塞/结构病因不能靠软腭训练解决。
- 36–41 仰头漱口的“死死上贴”不能直接迁移为说话目标；改轻松对比探索或专业示教，避免紧闭用力。

### 24. METRIC-VFP-THIN-01 — P1 / P2

文件：[单薄音色与闭合](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-VFP-THIN-01-充实音色-防止单薄如纸与声门闭合抗阻.md:15)

- P1，15、30–32：“CQ低于20%”“听着像轻薄烟雾说明闭合无力”。CQ是闭合时段比例，不是接触面积；听感/手机无法量出20%，不能诊断声带仅边缘振动或无力。这会驱使用户增加闭合/用力以解决未经证实的问题，需删除。
- P2，26、49：-24 dBFS及提高3–5 dBFS不能评估声带力量或真实响度，也随设备、增益、距离而变。先统一录音条件，仅作为录音电平反馈。
- P2，44–46：“mi/ni/di有力浊辅音…瞬间激活闭合”。普通话拼音d是清不送气塞音，不是浊/d/；辅音可用于协调但不保证闭合。改轻松示范并正确标记音值。
- P2，16 把咽腔收窄简单归为剧烈吸声损耗，不能解释所有单薄听感；3濒临断气幼童、17致命伤等删去。

### 25. METRIC-VOLUME-PROJECTION-01 — P1 / P2

文件：[投射与响度](/Users/dannyfeng/Documents/Pitchee/Docs/Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-VOLUME-PROJECTION-01-声音投射力-不挤喉咙的前提下增强响度.md:12)

- P1，30：“<-45dBFS且SNR<12dB说明声能出唇前已损耗殆尽”。数字电平/SNR反映录音输入和环境，不能定位声道能量损失或证明生理缺陷；可能只是麦克风远/增益低。先处理录音质量，不让用户以更用力克服设备问题。当前背景阈值为10dB，非12dB。
- P2，13–16 气压“冲刷喉头回最低位”、响度“从来不是发声用力而只是阻抗放大”。声源驱动力与声道作用共同影响输出；应说更有效率，不说仅靠共鸣。女高音3000Hz歌手共振峰类比不准确，参S8。
- P2，24–25 两倍音量无明确物理含义，F0骤降也不能诊断TA/男性模式。
- P2，42–46 固定200Hz/舌位/稳如磐石不是响度练习必须条件；适度提高响度通常可伴随F0变化。应在舒适范围逐步尝试，把清晰度、听者距离、用声负荷作为目标。

## 共性修订规则

1. 先区分：临床共识/原始研究结果、社区练习提示、产品规则、个人偏好；不混成“权威医学真相”。把“说明你…”改为“可能受…影响，单靠这个观察不能确定”。
2. 删除全部未注明样本/条件的贡献率、95%识别、80%隔音、固定厘米位置、万能Hz、几天必达标、必增10/20分。
3. 生理术语保持准确：声学基频/声道共振/感知音色/触觉反馈互不等同；CQ≠面积，F1≠VFP，M2≠病理假声，F0标准差≠Jitter，dBFS≠声压级或声带闭合。
4. 每项练习用可观察指令代替不可直接控制的肌肉/软骨指令：舒适音高、轻松音量、短时尝试、正常呼吸、有痛/明显紧张停。不要要求读者刻意复现挤压、锁喉或操作甲状舌骨间隙。
5. 命名和中文风格：删“残酷真相、死死、彻底、黄金、物理极限、秘密钥匙、奇迹、原形毕露、真/假声音、男声深坑”。多篇模板“核心目标”实际填的是病因，“症状排查”里放练习、“声学机制”里放算法/风格判断，应重整为“这项反馈能说明什么—可尝试什么—何时停止—证据来源”。
6. 参考文献需以实际题名、作者、年份、DOI/具体章节列出。大量 `ASHA：《某个具体专题名》` 实际都指向同一总览页；Vocal Congruence/Sheffield/TruVox主页也不等于文中那个自造题名的研究。已核实不等题名，不能把尚未找到逐篇内容的条目断言为“文章绝不存在”；应标“题名/对应段落未核实”。
7. 多篇相互冲突：耳语全有害却用无声气流做“最安全”练习；气泡音有时危险有时万能；重轻+小共鸣既理想又失衡；语调篇要求扩大变化，稳定篇让长句平直；自然度高等于健康却其他页口头反对唯分数。应集中统一术语和边界后再分发。

## 发布前建议

优先停止推荐含 P1 生理诊断、气道/咳嗽改造、喉部自操作、260Hz物理极限的现稿。先重写这些段落再做语言润色。可保留已验证的产品公式与常见练习方向，但应由受过嗓音临床训练者复核练习安全和医学表述。此审阅没有检查每个外部站点的全部子页面，不能将“当前链接没有支持”说成“整个项目无此观点”。
