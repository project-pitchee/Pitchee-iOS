# Readiness 评分引擎 v0.8

实现依据：`readiness-spec-for-astra.md`（2026-10-10 修订版），范围为纯计算与合成回测。入口在 `PitcheeApp/Analysis/ReadinessScoring.swift`，不接数据库、UI、Core 或现有 VoiceScoring/scoreProfile。

## 运行

```sh
./Scripts/test-readiness-scoring.sh
./Scripts/test-readiness-backtest.sh
```

两套程序独立编译生产引擎，不依赖 App 启动或原生模型。测试使用 Swift 6、完整并发检查与默认 MainActor 隔离；生产模型和计算类型均为 `nonisolated`、`Sendable`。回测报告见 `Readiness-Backtest-Report.md`。

## 输入与调用方合同

```swift
let result = ReadinessScoring.evaluate(input)
// 调用方将 result.markHeavyYesterday 保存为次日 heavyYesterday 输入，
// 并决定如何展示 result.isColdStart。
```

引擎仅接收已经选取好的快照。调用方负责：

- practiceDay 去重、7 天负荷、30 天窗口、近 30 天至少 12 天的习惯用户判定与缺席计数。
- 每条录音的 `canCompare` 和各特征质量门控。C 窗口保留最近三次的原始槽位；门控失败、特征缺失或旧录音没有 voiceQuality 时，对应槽位传 nil。不得先过滤再补更旧数据。
- 基线至少 5 个有效样本，标准差使用 n−1；只有 HNR 应用 0.5 dB floor。n/p/v 不引入 floor；无法信任的基线传 nil。σ 非正、非有限或 z 计算非有限时，引擎也会保守忽略该项。极小但有限正 σ 的业务拒绝阈值没有定义，本实现不自创阈值。
- `speechSecondsP90` 少于 5 个合格样本时传 nil。
- 持久化 A4 次日标记、每日缓存、冷启动文案与 guidedFirstRecording 行为。

`recentFinalScores` 使用最新在前的顺序。B1 先取前 5 条，再整体检查可比性，OLS 按从旧到新的方向计算；B2 固定最近 3 条，不补位。B3 只看最新一条和独立的 30 天基线。C 特征数组也约定最新在前，三次均值与顺序无关；严格要求恰好三槽且全部有效。

规格 §1 的关键字段与额外计算证据：

| 字段 | 原因 |
|---|---|
| `ReadinessInput.finalScoreBaseline: BaselineStats?` | §1/§4 的 B3 个人基线；nil 时 B3 不参与 |
| `ReadinessResult.markHeavyYesterday: Bool` | §1 的 A4 纯计算产物，供调用方持久化为次日输入 |
| `ReadinessResult.isColdStart: Bool` | 区分冷启动的 70/A 占位与实际评分，不把文案或 UI 行为引入引擎 |
| `FactorContribution.isTriggered: Bool` | 区分零分强制定级/已经满足的 cap 与未参与项 |
| `FactorContribution.direction: Int?` | 记录 C1 高于/低于基线的方向，不评价好坏 |

只有冷启动在评分前短路，结果中的 `markHeavyYesterday` 为 false。若调用方还需要在冷启动时生产 A4 标记，可独立调用纯函数 `ReadinessScoring.markHeavyYesterday(for:)`。非冷启动时总会完成 A/B/C 计算，再应用决策优先级。

## 分数与证据

默认依次从 70 开始计算 A1、A2、A4、B1、B2、B3、C1–C4。B2 固定 −15，未做任何“优化”。决策优先级为 #7 > #4 > #6，#5 在 A2 内生效，#3 的 −15 已计入 B2，不重复扣分。

每次结果均保留 A1、A2、A4、B1–B3、C1–C4 共 10 项贡献条，缺失、未触发、冷启动跳过的项贡献为零。A4 标记可为零贡献，等级覆盖、封顶和豁免另用 `decision.4/5/6/7` 记录；封顶贡献等于实际减少的分数。默认配置保证：

```text
score = 70 + sum(contributions.contribution)
```

不添加规格没有定义的 0–100 clamp 或等级边界修复：#7 只覆盖等级为 C，保留当时数字，reason 为 `.welcomeBack`；#4 只封顶并强制 B，原分小于 40 也不会加分。#6 只 cap64，然后按分数映射等级。消费者应直接使用输出 `level` 和 `reason`，不要从 score 重新推断强制定级。`level` 始终是 String。

顶层 `formulaVersion` 和 C1 贡献版本为规格要求的 `c1-bidirectional-v1`；双异常决策条版本为 `dual-anomaly-v1`；其余贡献条版本更新为 `readiness-v0.8-r2-uncalibrated`，以区分本次规则修订。

## 合成回测画像与预期修订

P1 的核心断言已修正为“无封顶、无 C”，实测通过，分布保持 21 次 S、9 次 A。历史“始终 A”的预期没有计入 A1 的全勤奖励，属于已修正的画像预期问题；70 加上最高 +20 达到 S 是当前公式的正确输出，不再视为未解决的公式冲突。

贡献条进一步区分：9 个 A 天中，day5/9/13/17/21/25/29 共 7 天由 ±3 分噪声触发 B2 −15，另 2 天（day1/2）为冷启动。报告保留这一精确归因和 B2=0 的配对反事实，作为待决策 #29 的 supporting evidence；没有把全部 9 天误写为 B2 触发。A1 最高 +20 是 B1 +5 的 4 倍，慷慨度仅记录为 G 未校准观察，不调参。

P2 每 5 次 +2 分不足以满足 B1 的 slope >1 分/次，回测保留这一结果，按新版规格命名超过阈值的进步对照为 P2b。P3a/P3b 共用负荷，只有 HNR 方向相反；主对照两者均为 59/B。P4 检查 day3 超量、day4 的 64/B，并检查第 7/8 天继续计算表现、嗓音和次日标记。P5 检查两个 HNR 方向都不能单独触发封顶。不变量 #5 只校验 P8 回归态为 C、reason 为 `.welcomeBack`。

P9 为 30 天隔日练习，15 条真实录音沿用 P1 的每条录音 70±3 噪声，逐日计算 30 次 Readiness（含 15 个休息日）。核心断言为 A 档超过一半、无封顶、无 C。报告分别列出练习日/休息日及冷启动/已评分的等级分布；休息日不补造录音、不补零或插值。A2 和 B2 的叠加效果也按实际贡献保留。

参数扫描逐个将现值乘 0.8 和 1.2，再运行全部 9 类画像（P3 分 a/b，共 10 个变体），与原配置的同一观察点比较等级。每个画像、每个方向的翻转率均单独报告；达到 10% 即标“不稳定”。P9 的 30 个逐日观测纳入每个扫描方向的分母，P2b 仍为独立正控，不纳入画像扫描。不把不稳定结果隐藏或自动调整参数。当前实现扫描 30 个引擎参数，另独立扫描调用方 HNR floor；包含全部显式 G 数值及保守纳入的全局分数、冷启动、等级、回归阈值，未给这些全局值冒充置信度等级。

天数/资格数量阈值以 Double 比较，使 ±20% 扰动保留意义；B1 实际取样窗口必须是整数，使用四舍五入。固定三时刻对齐和 B2 三点模式属于结构规则，不改变。30 天取数与质量/基线样本规则属于调用方；harness 单独检查这些准备步骤及 HNR floor，不把统计工作移入引擎。

所有 G 级参数仍为未校准。敏感度扫描只是暴露脆弱性，不证明真实人群准确率。B2 误伤对照单独列出默认 −15 与仅关闭 B2 的诊断反事实；关闭仅发生在 harness，不改变生产默认值。待决策 #29 仍然开放。
