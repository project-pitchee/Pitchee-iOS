# 嗓音训练知识库修订记录

修订日期：2026-10-05。已重写现有 49 篇文章，覆盖 8 个模块，并生成当前 iOS 内置资源。本文是修订记录；[原审查报告](Voice-Training-Library-Audit-2026-10-05.md)保留为修订前快照，旧行号不适用于新版。

第二轮再次复核全部 49 篇，在第一轮基础上进一步修改 45 篇；其余 4 篇经检查保留。逐篇差异保存在[第二轮内容记录](Research-Evidence/voice-training-reader-2026-10-05/content-second-pass-changes.json)。本轮重点如下：

- 给规则解释、初次录音、A/B 回听、日常迁移及录音排查补充具体操作、观察点和下一步选择，删减围绕旧错误展开的反复否定。
- 区分基频与主观音高，说明 /a/ 与 /ɑ/ 的读法差异；补充共振峰估计的片段选择、参数记录和不确定结果处理。
- 增加连续评分与 pass_boost 的实算例子；说明命中加分分支可能仍保留较高的基础分。公式含义不变，长公式分段以便阅读。
- 进一步核对 TWVQ 的信度与效度、30 题总分范围，以及嘶哑四周未改善和突发明显声音改变时的处理表述。
- 澄清 App A/B 使用当次固定文本，结果面板不显示每段 F0 轨迹；“减少依赖音色分”指个人练习选择，不是修改评分权重。

## 主要变化

| 主题 | 修订后的处理 |
|---|---|
| 音色分（VFP） | 统一中文名，明确是模型反馈，不是共振峰或解剖测量；允许误判和系统性偏差 |
| 自然分 | 按日常说话的自然听感、刻意和风格化程度解释；不作为机器人检测、健康或肌肉状态指标 |
| 指标组合 | 高 F0、高音色分与低自然分可以共存，没有必然的单一发声机制解释 |
| 完整对话 | 纳入语调、韵律、情感、语言与情境；现有综合分不能完整代表这些因素或听者识别概率 |
| 模型误判 | 相同录音条件和重复低分不能排除系统性误判；VFP 导向文章先检查适用性，允许跳过 |
| F1–F4 | 单独介绍持续元音估计与未来共鸣分设计，区分 F0、谐波、共振峰和模型分数 |
| 元音 | /i/ 已按用户确认；/ae/ 规范为 /æ/；拟议 /a/ 与研究中的 /ɑ/ 分别标注 |
| 模块 02/03 | 从分数对应阶段或病理的写法，改成可观察的练习目标、方法及测量边界 |
| 生理与安全 | 删除由分数诊断损伤、按压喉部、热水蒸汽及固定禁声处方；统一需尽快评估与急症表述 |
| 学习过程 | 删除固定见效期、固定性别音区、分数下降证明进步和两周后必涨分等承诺 |
| TWVQ / WPATH | 使用正确论文题名、授权问卷与作者说明；移除自编分段和统一术前训练期限 |
| 中文风格 | 重写标题，去掉贬损声线、制造焦虑和伪精确表达；每篇保留可执行且可放弃的观察方法 |

## 共振峰方案的证据边界

[共振峰主文](Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-VFP-DARK-01-共鸣提亮-舌背隆起与咽腔缩小实战.md)说明选定元音、保持可比条件、估计共振峰、检查可靠性及回到词句的流程。

[Gallena 等的研究](https://pubmed.ncbi.nlm.nih.gov/28844651/)操控 F1–F3，使用 /i/、/æ/、/ɑ/、/u/，没有验证通用 F1–F4 百分制评分。F4 在新版中是可选扩展观察。没有把四峰平均或整体升高定义成女性化，也没有承诺所有情境下的性别感知。

当前检查的 iOS 和 Core 源码未找到独立元音选择及 F1–F4 评分流程。因此本次交付的是文章和设计说明，没有新增共振峰估计或共鸣分算法。后续实现需要元音一致的参考数据、估计质量判据及独立验证，见[架构说明](Voice-Training-System-Architecture.md)。

## 产品集成

- 保留全部 49 个稳定 ID、文件名、JSON schema 与 17 个匹配分类；实际展示采用新版文章标题。旧文件名作为兼容路径保留，不是正文结论。
- 同步知识库与 `Resources/VoiceTrainingLibrary` 的 JSON，修订日期写入每篇正文。
- 构建脚本只镜像到实际使用的文章来源，不再自动覆盖旁边另一份 Articles 检出。
- 阅读器支持新版四节标题，保留第四节完整依据说明，删除额外的重复参考区与分类默认参考列表；修正行内公式分隔符、表格列对齐，并为独立长公式增加横向滚动。可视检查范围见验收记录。
- 低 VFP 建议先提示核对听感和模型误判，允许跳过；未改动评分公式或匹配条件。结果页与建议文案同步简体中文、繁体中文和英文，共进一步修正 25 个键、75 个译文值，并对齐 6 处 Swift 默认文案；其他语言未在本轮重新翻译。

## 验证

已执行并通过：

- `python3 Scripts/build-voice-training-library.py`：从当前来源生成 49 篇资源。
- `bash Scripts/test-voice-training-library.sh`：49 篇结构、元信息、四节正文、图标和 17 个匹配分类校验，以及 Swift 推荐匹配测试。
- 独立检查：修订前后文章 ID 一致；Markdown 与 JSON rawContent 一致；App 与来源 JSON 镜像一致；原有 30 处相对链接已替换为 4 个核验过、内容一致的固定提交 HTTPS 来源；第二轮后 136 处文章引用使用 34 个不同的 HTTPS 地址。
- 第二轮内容重新构建并通过既有知识库检查；三组新增公式例算独立计算一致，Core 评分源码散列保持不变。详见[内容一致性记录](Research-Evidence/voice-training-reader-2026-10-05/content-validation.json)和[检查日志](Research-Evidence/voice-training-reader-2026-10-05/library-tests.log)。
- 全库术语与重点错误扫描；分模块逐篇自审及跨模块交叉复核。复核发现的就医分级、削波定义两处问题已修正。
- 主仓库与文章子仓库 `git diff --check` 通过；本次触及的本地化 JSON 可解析。

这些检查验证内容结构和现有集成，没有重新训练或验证 VFP / 自然分模型，也没有进行新的临床试验。后续阅读器检查和模拟器证据见 [阅读器验收记录](Voice-Training-Reader-Verification-2026-10-05.md)；真机仍未验收。TWVQ 论文使用已核公开摘要及授权说明，未把未取得的完整论文当作已阅读全文。

## 用户补充规则的核对

用户已确认冲突以 Core 源码为准：高基频、低自然分保留 30 分封顶，音色不足分支使用自然分 ≥50。综合式及其他规则不变。连续评分文章补充了用 F0 / 自然分约束 VFP 的产品设计意图，并区分连续联合项与 pass_boost；不会把这些参数写成人类听感或器官状态的确定界线。

## 49 篇文章索引

| 稳定 ID | 新标题 |
|---|---|
| `RULE-CONTINUOUS-01` | [读懂连续评分：音色分、自然分与音高怎样参与计算](Voice-Training-Library/Module-01-Engine-Rules/RULE-CONTINUOUS-01-连续评分逻辑与各指标协同进展.md) |
| `RULE-F0-UNAVAILABLE-01` | [音高没有检出：先检查录音，再区分耳语与有声发音](Voice-Training-Library/Module-01-Engine-Rules/RULE-F0-UNAVAILABLE-01-告别耳语-为什么系统检不出基频.md) |
| `RULE-F0-UNAVAILABLE-02` | [从呼气到有声短句：探索轻松的发声起始](Voice-Training-Library/Module-01-Engine-Rules/RULE-F0-UNAVAILABLE-02-从气流到实声-声门闭合与发声起始.md) |
| `RULE-HIGH-F0-MALE-01` | [音高与音色分不同步：理解女性向 59 分上限](Voice-Training-Library/Module-01-Engine-Rules/RULE-HIGH-F0-MALE-01-突破59分瓶颈-声道体型感与共鸣对齐.md) |
| `RULE-HIGH-F0-MALE-02` | [元音与音色变化：在清晰表达中探索不同听感](Voice-Training-Library/Module-01-Engine-Rules/RULE-HIGH-F0-MALE-02-口咽腔形变与元音变色提亮.md) |
| `RULE-HIGH-F0-MALE-03` | [音色、听感重量与表达风格：寻找自己喜欢的组合](Voice-Training-Library/Module-01-Engine-Rules/RULE-HIGH-F0-MALE-03-摆脱卡通音-声带重量与共鸣平衡.md) |
| `RULE-HIGH-F0-STYLIZED-01` | [音高较高、自然分较低：理解 30 分上限](Voice-Training-Library/Module-01-Engine-Rules/RULE-HIGH-F0-STYLIZED-01-告别挤卡-打破30分封顶.md) |
| `RULE-HIGH-F0-STYLIZED-02` | [半封闭声道练习：把唇颤或吸管发声作为可选尝试](Voice-Training-Library/Module-01-Engine-Rules/RULE-HIGH-F0-STYLIZED-02-SOVTE半封闭声道与吸管吹唇发声.md) |
| `RULE-HIGH-F0-STYLIZED-03` | [认识 M1、M2 与听感重量：不靠分数给声带分类](Voice-Training-Library/Module-01-Engine-Rules/RULE-HIGH-F0-STYLIZED-03-声带边缘振动-从M2假声到轻质M1.md) |
| `RULE-LOW-F0-NATURAL-01` | [探索稍高的音高：从舒适短音接回说话](Voice-Training-Library/Module-01-Engine-Rules/RULE-LOW-F0-NATURAL-01-松弛不挤喉-安全提升基频滑音阶.md) |
| `RULE-LOW-F0-NATURAL-02` | [保留偏好的音高：同时理解整体听感与算法上限](Voice-Training-Library/Module-01-Engine-Rules/RULE-LOW-F0-NATURAL-02-中性音区应用-基频不硬飙的女性化补偿.md) |
| `RULE-LOW-F0-STYLIZED-01` | [理解 20 分上限：把模型结果与身体感受分开](Voice-Training-Library/Module-01-Engine-Rules/RULE-LOW-F0-STYLIZED-01-排查20分卡点-下压喉结与气道受阻解绑.md) |
| `RULE-LOW-F0-STYLIZED-02` | [练习前后如何放松：可选的轻叹与自然停顿](Voice-Training-Library/Module-01-Engine-Rules/RULE-LOW-F0-STYLIZED-02-打哈欠叹气法与外喉肌松绑.md) |
| `RULE-PASS-BOOST-01` | [理解 pass_boost：从短句尝试过渡到较长表达](Voice-Training-Library/Module-01-Engine-Rules/RULE-PASS-BOOST-01-协同突破与长篇拓展.md) |
| `RULE-PASS-BOOST-02` | [把偏好的声音带入生活：允许情绪与场景变化](Voice-Training-Library/Module-01-Engine-Rules/RULE-PASS-BOOST-02-生活实战与动态情绪保持.md) |
| `SCORE-ADVANCED-01` | [从朗读走向聊天：探索适合情境的自然表达](Voice-Training-Library/Module-02-Score-Ranges/SCORE-ADVANCED-01-从80分到90分-消除播音腔与假面感.md) |
| `SCORE-ADVANCED-02` | [语速、重音与停顿：让节奏服务于你想表达的意思](Voice-Training-Library/Module-02-Score-Ranges/SCORE-ADVANCED-02-语速韵律-让声音灵动流淌的停顿艺术.md) |
| `SCORE-MASTER-01` | [把满意声音带入生活：迁移、休息与表达灵活性](Voice-Training-Library/Module-02-Score-Ranges/SCORE-MASTER-01-90分选手终极挑战-全天候生活自动化.md) |
| `SCORE-MASTER-02` | [长期用声照护：水分、负荷与反流相关疑问](Voice-Training-Library/Module-02-Score-Ranges/SCORE-MASTER-02-长期嗓音卫生与反流预防保嗓守则.md) |
| `SCORE-MID-01` | [让满意的尝试更容易重现：听觉反馈与练习提示](Voice-Training-Library/Module-02-Score-Ranges/SCORE-MID-01-从60分到75分-喉腔记忆与自我监控回路.md) |
| `SCORE-MID-02` | [安排练习节奏：让短时尝试与休息适合你的日常](Voice-Training-Library/Module-02-Score-Ranges/SCORE-MID-02-练习排期-每日15分钟高效微练习节奏.md) |
| `SCORE-STARTER-01` | [从第一次录音开始：选择一个清楚、可重复的练习目标](Voice-Training-Library/Module-02-Score-Ranges/SCORE-STARTER-01-面对50分以下-拆解声学生理微习惯.md) |
| `SCORE-STARTER-02` | [回听带来压力时：把声音观察与自我评价分开](Voice-Training-Library/Module-02-Score-Ranges/SCORE-STARTER-02-心理调适-嗓音性别焦虑自护与客观解耦.md) |
| `METRIC-DURATION-SHORT-01` | [录音太短或一句话说不完：分别处理录音与换气](Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-DURATION-SHORT-01-气息支撑-胸腹联合呼吸与慢呼气训练.md) |
| `METRIC-NATURAL-LOW-01` | [理解自然分：日常说话听感与风格化表达](Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-NATURAL-LOW-01-自然度重构-声带过度撞击与声门漏气消除.md) |
| `METRIC-NATURAL-TENSION-01` | [练习后发紧或酸痛：如何调整，以及何时寻求评估](Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-NATURAL-TENSION-01-喉外肌过度活动综合征MTD排查.md) |
| `METRIC-PITCH-HIGH-01` | [音高较高时：寻找适合自己与情境的说话范围](Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-PITCH-HIGH-01-避免过犹不及-寻找黄金频段190-220Hz.md) |
| `METRIC-PITCH-MONOTONE-01` | [探索语调变化：保留普通话声调，也表达自己的意思](Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-PITCH-MONOTONE-01-语调起伏-拯救机械音与上升语调.md) |
| `METRIC-PITCH-UNSTABLE-01` | [理解音高波动：区分语调、非自愿变化与追踪误差](Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-PITCH-UNSTABLE-01-音准稳定-腹式呼吸与声带张力微调.md) |
| `METRIC-VFP-DARK-01` | [从音色探索到单元音分析：认识 F1–F4 共振峰](Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-VFP-DARK-01-共鸣提亮-舌背隆起与咽腔缩小实战.md) |
| `METRIC-VFP-NASAL-01` | [鼻音与明亮感：分清正常鼻化、鼻塞和音色选择](Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-VFP-NASAL-01-告别夹鼻音-软腭升降与真共鸣辨析.md) |
| `METRIC-VFP-THIN-01` | [声音偏轻时：探索清晰度、响度与个人喜欢的质感](Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-VFP-THIN-01-充实音色-防止单薄如纸与声门闭合抗阻.md) |
| `METRIC-VOLUME-PROJECTION-01` | [让别人听清：响度、距离与声音投射](Voice-Training-Library/Module-03-Acoustic-Dimensions/METRIC-VOLUME-PROJECTION-01-声音投射力-不挤喉咙的前提下增强响度.md) |
| `MASCULINE-BASICS-01` | [男性向声音探索：音高、音色与表达方式](Voice-Training-Library/Module-04-Masculine-Voice/MASCULINE-BASICS-01-男性向嗓音基础-扩大声道与胸腔共鸣协同.md) |
| `MASCULINE-INTONATION-01` | [男性向表达中的语调与重音选择](Voice-Training-Library/Module-04-Masculine-Voice/MASCULINE-INTONATION-01-男性语调特征-平稳沉着与着重降调结构.md) |
| `MASCULINE-LARYNX-01` | [探索较低声音时，怎样减少用力与压喉](Voice-Training-Library/Module-04-Masculine-Voice/MASCULINE-LARYNX-01-避免压喉坏嗓-松弛降低喉头的正确方法.md) |
| `MASCULINE-ON-T-01` | [使用睾酮期间的嗓音变化与照护](Voice-Training-Library/Module-04-Masculine-Voice/MASCULINE-ON-T-01-变声期嗓音管理-睾酮变声期间的破音与水肿防护.md) |
| `MASCULINE-PRE-T-01` | [未使用睾酮时的男性向声音探索](Voice-Training-Library/Module-04-Masculine-Voice/MASCULINE-PRE-T-01-未用睾酮激素Pre-T的声音降低指南.md) |
| `NONBINARY-EXPLORE-01` | [中性与多元声音：按自己的目标探索](Voice-Training-Library/Module-05-NonBinary-Exploration/NONBINARY-EXPLORE-01-中性与多元声音探索-在145-165Hz找到属于你的性别平衡.md) |
| `NONBINARY-FLUIDITY-01` | [在不同场景使用不同声音：练习切换与保留选择](Voice-Training-Library/Module-05-NonBinary-Exploration/NONBINARY-FLUIDITY-01-嗓音流动性-声线自由切换指南.md) |
| `PRACTICE-AB-DROP-01` | [A/B 复测分数下降：先确认变了什么](Voice-Training-Library/Module-06-Guided-Practice-AB/PRACTICE-AB-DROP-01-AB复测得分下降-动作重塑期的正常波动.md) |
| `PRACTICE-AB-SUBJECTIVE-01` | [听感更接近目标，分数却没变：怎样使用这次反馈](Voice-Training-Library/Module-06-Guided-Practice-AB/PRACTICE-AB-SUBJECTIVE-01-自评困惑-听感更接近目标但分数没变的原因.md) |
| `PRACTICE-AB-UNSURE-01` | [回听时无法判断：把问题缩小，再决定要不要继续](Voice-Training-Library/Module-06-Guided-Practice-AB/PRACTICE-AB-UNSURE-01-听辨训练-从听着迷茫到精准自察.md) |
| `QUALITY-CLIPPING-01` | [录音提示可能削波：先调整采集，再比较声音](Voice-Training-Library/Module-07-Recording-Quality/QUALITY-CLIPPING-01-解决clipping削波-爆音对声学特征的破坏及防喷麦技巧.md) |
| `QUALITY-ENVIRONMENT-01` | [电平过低或背景干扰：让录音条件更可比](Voice-Training-Library/Module-07-Recording-Quality/QUALITY-ENVIRONMENT-01-排查lowLevel与background-麦克风距离与信噪比指南.md) |
| `HEALTH-CLINICAL-01` | [何时寻求嗓音支持，如何准备就诊](Voice-Training-Library/Module-08-Health-Psychology-Clinical/HEALTH-CLINICAL-01-就医指南-何时寻求嗓音支持专家与咽喉科医生专业帮助.md) |
| `HEALTH-HYGIENE-01` | [日常嗓音照护：补水、休息与用声安排](Voice-Training-Library/Module-08-Health-Psychology-Clinical/HEALTH-HYGIENE-01-嗓音卫生全书-日常护嗓水分补给与科学冷身.md) |
| `HEALTH-REDLINE-01` | [练声后出现疼痛、嘶哑或失声时怎么办](Voice-Training-Library/Module-08-Health-Psychology-Clinical/HEALTH-REDLINE-01-安全红线-刺痛干涩与嘶哑失声的紧急处置.md) |
| `HEALTH-TWVQ-01` | [认识 TWVQ-SC：记录嗓音与生活体验](Voice-Training-Library/Module-08-Health-Psychology-Clinical/HEALTH-TWVQ-01-科学自评-跨性别女性嗓音问卷TWVQ-SC与生活质量量表.md) |
