# Readiness 取数调用方

`ReadinessView` 使用环境里的同一个 SwiftData `ModelContext` 创建 `ReadinessProvider`，在页面 task、回到前台和北京时间 04:00 调用 `result(at:)`。页面直接显示引擎的 `score`、字符串 `level`、`reason`、`contributions`；调用方不重新推断等级或计算贡献。

```swift
let provider = ReadinessProvider(modelContext: modelContext)
let result = try provider.result()
```

## 取数口径

- `practiceDay` 固定北京时间 04:00 起算，不使用设备时区。基线包含 `[day−29, day]`，且排除查询时刻之后的录音。
- 练习历史就是 `RecordingAssessment`；有记录即计活动日，不要求可选的 `practicePayload` 或 cohort。近 7 天、习惯用户的 30 天活动均按日去重。`gapDays` 与连续缺席数为今天到最近记录日的距离；今天已有记录为 0，空历史为 0。不额外推断首次回归录音之前的缺席覆盖状态。
- `validAssessments` 是截至查询时刻、终身 `canCompare && finalScore.isFinite` 的录音次数。旧记录只按 128 条批量读取分数和质量列，统计过程不读旧录音的 `resultPayload`。
- B 用保存的 `finalScore` 和 `quality?.canCompare == true`，不调用偏好重评分。最近 B 5 条、C 3 条先截取原始时间槽位，再分别门控；这些槽位不按日合并。某个槽位缺失时保持 nil，不向更老记录补位。不足 3 条时 C 补 nil 槽位。
- 基线先按每个特征质量门控，再取每日中位数（用户已确认，沿用 `DailyPracticeSummary` 的中位数口径），至少 5 个有效日才计算均值与 n−1 样本 SD。只有 HNR 设 0.5 dB floor；其他基线 SD 为零或非有限即 nil，包括仅传均值的 v。
- 今日 speechSeconds 对实际记录的有限非负语音时长按日求和，不因比较质量不合格而丢弃负荷；没有时长值时为 nil。P90 额外按 `canCompare` 门控有效练习样本，对至少 5 个有效日总量做线性分位数，包含当日。

## 存储字段对应

| 引擎输入 | 当前存储来源 |
| --- | --- |
| h | `resultPayload.voiceQuality.hnrDb`，且 `hnrWindowCount >= 10`、`canCompare` |
| n | `RecordingAssessment.naturalnessScore`，来自原始 `naturalness.score` |
| p | `resultPayload.f0.standardDeviationHz`（现有 `pitchVariationHz` 的同一来源） |
| v | `f0.voicedFrameCount / f0.totalFrames`，仅两者实际存在、计数有效时 |

当前 schema 只有 HNR 放在 `voiceQuality`；n/p 已有独立字段。当前录音 **没有保存 `totalFrames`**，所以真实数据的 C4 保持 nil/零贡献，不从时长或窗口数量估算分母。投影可读取显式存在的可选 `f0.totalFrames`，seeded 测试独立覆盖这个分支；没有修改 Core 或录音 schema。

声学数据使用局部 `Decodable` 标量投影，只在 30 天窗口和最近 5 条录音窗口内读取。不会调用完整的 `RecordingAssessment.result` / `hnrDb` 或 `InsightsData.dailySummary`；窗口数组未建模，因此不会解码成数组。某个标量损坏只使对应特征缺失。

## 缓存与次日标记

`UserDefaults` 的 `readiness.daily.cache.v1` 保存一个派生缓存信封：practiceDay、完整引擎结果、规则版本和可选 heavy 生效日。历史仍只有原 SwiftData 存储。

同一天再次打开页面、创建新 provider 或重启 App 直接读取缓存，不重新取数/评分。当天新增录音也不使缓存失效。次日输入仅在 heavy 生效日等于当前 practiceDay 时为 true；成功生成新缓存时消费并清除旧标记。如当前引擎结果又标 heavy，则只安排下一日。跨过生效日才打开会丢弃过期标记。读取失败不会提前消费；缓存序列化完成后才一起写入结果和标记。

`ReadinessScoring.swift`、Core、`VoiceScoring`、`scoreProfile`、`AnalysisViewModel` 均不属于本次改动。B2 继续 −15、未校准。

## 验证

```sh
./Scripts/test-readiness-provider.sh
./Scripts/test-readiness-scoring.sh
```

调用方测试用真实 `RecordingAssessment` / SwiftData 内存容器及隔离的 UserDefaults，覆盖取数、引擎、缓存的完整链路。编译开启 Swift 6、默认 MainActor、完整并发检查及 warnings-as-errors；UI 则随 iOS Simulator App 构建验证。验收包含 `score = 70 + sum(contributions.contribution)`、v3 HNR 空槽、每日缓存和次日标记生命周期。

2026-10-10 验证结果：调用方 62 项检查通过，含新建 ModelContext 重新读取已保存数据；seeded 完整链路 `score = 55`、`level = "B"`、贡献总和 `−15`，B2 仍为 `−15`。原引擎 4,425 项检查通过。包含真实调用方与页面的 iOS Simulator Debug 构建通过，本地化校验通过。
