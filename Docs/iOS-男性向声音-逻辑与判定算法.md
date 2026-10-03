# iOS 端男性向声音：逻辑、实现与判定算法

本文根据当前代码（Pitchee iOS、PitcheeCore C++）整理。文中的“男性向”是用户主动选择的**练习目标方向**，用于把同一份声音分析结果转换成目标方向分数；它不判断用户的性别身份，也不声称声音存在唯一的性别标签。当前实现没有单独训练一个“男性模型”，而是复用现有模型结果做方向性变换。

## 1. 入口与总体数据流

```text
用户选择“男性向声音”
        │
        ├─ 保存 VoicePreference.masculine（兼容旧版中文持久化值）
        │
录音 PCM
        │
        ├─ iOS：写原始 WAV；实时流送入 16 kHz 单声道 F0
        └─ Core：统一预处理并完成离线分析
             ├─ 单声道化、重采样到 16 kHz、PCM16 量化
             ├─ Silero VAD → 语音段 / VFP 窗口
             ├─ SwiftF0 → 置信度筛选后的平均 F0
             ├─ ECAPA → VFPHead → VFP（女性向参考分）
             ├─ ECAPA embedding → Naturalness
             └─ Core 原始 composite（女性向参考）
        │
        └─ VoiceDirectionScore.masculineComposite
             ├─ Standard = 100 - VFP
             ├─ 反向 F0 贡献
             ├─ 连续基础分
             └─ 加分 / 封顶 / 缺失 F0 回退
```

相关实现位置：

| 层 | 文件 | 作用 |
|---|---|---|
| 方向枚举与男性向评分 | [`PitcheeApp/Analysis/VoiceScoring.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/VoiceScoring.swift) | `VoicePreference`、`VoiceDirectionScore`、男性向公式和规则 |
| 原生打分 | [`Dependencies/PitcheeCore/src/scoring.cpp`](/Users/dannyfeng/Documents/Pitchee/Dependencies/PitcheeCore/src/scoring.cpp) | 原始女性向参考 composite；同时作为 Swift 男性向镜像的 C++ 参考实现 |
| 原生分析编排 | [`Dependencies/PitcheeCore/src/analyzer.cpp`](/Users/dannyfeng/Documents/Pitchee/Dependencies/PitcheeCore/src/analyzer.cpp) | F0、VAD、VFP、自然度、结果 JSON |
| Swift/C++ 桥接 | [`PitcheeApp/Interop/Core/CoreAnalyzer.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Interop/Core/CoreAnalyzer.swift) | actor 串行化 Core 调用、实时 F0 |
| 结果模型 | [`PitcheeApp/Interop/Core/AnalysisResult.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Interop/Core/AnalysisResult.swift) | F0、VFP、自然度、Core composite DTO |
| 结果展示 | [`PitcheeApp/Analysis/RecordingAnalysisView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift) | 男性向分数、公式和规则说明 |
| 历史与趋势 | [`PitcheeApp/Analysis/RecordingAssessment.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAssessment.swift)、[`PitcheeApp/Insights/InsightsData.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsData.swift) | 保存原始结果，按当前方向动态重算 |

评分规则版本为 `directional-core-v1`；模型清单版本为 `2026-09`。

## 2. 录音进入算法前的处理

1. iOS 录音同时保留原始 WAV，并把连续的 Float32 单声道采样送给实时 F0。Core 离线分析接收源采样率、声道数和 PCM 缓冲。
2. Core 先把多声道按帧平均为单声道。
3. 采样率统一到 16,000 Hz。重采样使用相位滤波器和 Kaiser 窗；输入会量化到 PCM16 等价的 Float32（`round(value * 32768) / 32768`，并限制在 `[-1, 1)`）。
4. 当前 `kMaximumSeconds` 为无穷大，因此 Core 不主动截断录音。

这些处理决定了后续 VAD、F0 和 embedding 的实际输入；男性向公式本身只消费 Core 输出的 `VFP`、`Naturalness` 和平均 `F0`。

## 3. Core 输出的三个评分输入

### 3.1 F0（基频）

`SwiftF0.onnx` 对 16 kHz 信号输出逐帧基频和置信度。当前判定条件为：

- `confidence > 0.9`
- `75 Hz <= f0 <= 600 Hz`

通过条件的帧才算 voiced frame。帧时间戳为：

```text
timestamp = (frameIndex * 256 + 127.5) / 16000
```

全局平均 F0 是所有 voiced frame 的算术平均；标准差使用总体方差（除以 voiced frame 数量）。没有有效 voiced frame 时，`meanHz` 为 `nil`。

另外，Core 将 F0 按 50 ms 窗口聚合：每个窗口内的有效帧取平均，窗口只用于展示和统计；男性向 composite 使用的是全局 `meanHz`。

### 3.2 VFP（女性向参考分）

VAD 先确定语音段，再以语音段生成窗口：

- 目标采样率：16 kHz；
- patch 长度：`24,240` samples（约 1.515 s）；
- stride：`1,600` samples（0.1 s）；
- 短于一个 patch 的语音段保留为一个窗口；较长语音段从起点按 stride 滑窗，并额外补最后一个覆盖尾部的窗口。

每个窗口经过 `ECAPAFrontend.onnx` 和 `ECAPA.onnx` 得到 192 维 embedding，再由 `VFPHead.onnx` 输出窗口概率。Core 将窗口概率的算术平均乘以 100，并限制到 `[0, 100]`：

```text
VFP = clamp(mean(windowProbability) * 100, 0, 100)
```

这里的 VFP 是代码和存储中的**女性向参考分**，不是男性向分。男性向先取其补数。

### 3.3 Naturalness（自然度）

自然度复用同一组 ECAPA embedding，而不重新切另一套窗口：

1. 每个 192 维 embedding 做 L2 归一化；
2. 求归一化 embedding 的均值向量，并再次 L2 归一化；
3. 对每一维计算总体标准差；
4. 拼接 `mean(192) + std(192)`，形成 384 维特征；
5. `Naturalness.onnx` 输出分数，最后限制到 `[0, 100]`。

男性向算法把这个分数作为自然度输入，不做方向取反。

### 3.4 VAD 与语音窗口判定

男性向 composite 不直接读取 VAD 概率，但 VAD 决定哪些音频进入 VFP 和自然度模型。当前 `SileroVAD.onnx` 的调用和后处理为：

- 每次输入 `512` 个采样，并拼接前一块的 `64` 个上下文采样；状态张量为 `[2, 1, 128]`；
- 语音开始阈值 `0.60`，结束阈值 `0.30`；
- 连续语音和静音的最短时长都为 `80 ms`；
- 语音段边缘增加 `20 ms` padding；相邻段间隙小于 `40 ms` 时，padding 在两段之间均分；
- 每个候选段再做周期性检查：400 samples 帧、160 samples hop、Hamming 窗，在 lag 32–212 范围寻找归一化自相关最大值；最大周期性至少 `0.50`，且满足周期性阈值的帧占比至少 `0.12`，否则丢弃为 breath-like 段；
- 保留周期性帧覆盖范围，并在首尾各扩展 80 samples；这会产生 `speechStartSeconds / speechEndSeconds`，同时保留原始时间轴的 `startSeconds / endSeconds`。

因此，呼吸声或无明显周期性的段不会进入男性向的 VFP/Naturalness 输入。VAD 没有直接给男性向分加分或扣分；它通过输入窗口选择间接影响 VFP 和自然度。

## 4. 男性向分数的定义

在 [`VoiceDirectionScore.masculineComposite`](</Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/VoiceScoring.swift:66>) 中，先做有限值和范围保护：

```text
S = Standard = clamp(100 - VFP, 0, 100)
N = Naturalness = clamp(Naturalness, 0, 100)
```

因此，VFP 越低，男性向 `Standard` 越高。注意这是对现有女性向参考结果的方向补数，不是重新训练或重新校准 VFP 模型。

### 4.1 F0 归一化

有有效 F0 时，男性向采用低音高贡献：

```text
F0r = clamp((200 - F0) / 90, 0, 1)
```

含义如下：

- `F0 <= 110 Hz` 时，F0 贡献封顶为 `1`；
- `F0 = 200 Hz` 时，F0 贡献为 `0`；
- `F0 >= 200 Hz` 时，F0 贡献保持为 `0`；
- 在 110–200 Hz 之间线性变化。

自然度归一化为：

```text
Nr = clamp((N - 40) / 50, 0, 1)
```

所以 `N <= 40` 为 0，`N = 90` 及以上为 1。

### 4.2 连续基础分

```text
Sr   = S / 100
Base = 100 * (
          0.50 * Sr
        + 0.20 * Nr
        + 0.15 * F0r
        + 0.15 * Sr * Nr * F0r
       )
```

四项分别表示：

| 项 | 权重 | 含义 |
|---|---:|---|
| `Sr` | 0.50 | 男性向 Standard 主贡献 |
| `Nr` | 0.20 | 自然度贡献 |
| `F0r` | 0.15 | 低音高贡献 |
| `Sr * Nr * F0r` | 0.15 | 三项同时较好时的交互贡献 |

连续规则默认 `Final = Base`。随后按固定的 `if / else if` 顺序应用规则；一条记录最多命中一条规则。

## 5. 男性向规则与边界

设 `F0` 为全局平均基频，`N` 为自然度，`S` 为男性向 Standard。

| 优先级 | 内部 rule | 条件（严格按代码） | 计算 | 说明 |
|---:|---|---|---|---|
| 1 | `masculine_pass_boost` | `F0 < 145` 且 `N > 80` 且 `S > 50` | `Final = max(Base, promoted)` | 低音高、自然度和方向一致性同时较好时加分 |
| 2 | `masculine_low_pitch_stylized_cap` | `F0 < 145` 且 `N < 50` | `Final = min(Base, 30)` | 低音高但自然度不足，限制分数 |
| 3 | `masculine_high_pitch_cap` | `F0 >= 145` 且 `N >= 50` | `Final = min(Base, 59)` | 音高仍偏高时保留上限 |
| 4 | `masculine_high_pitch_stylized_cap` | `F0 >= 145` 且 `N < 50` | `Final = min(Base, 20)` | 音高偏高且自然度不足，使用更严格上限 |
| 5 | `masculine_low_pitch_feminine_cap` | `F0 < 145` 且 `N >= 50` 且 `S < 50` | `Final = min(Base, 59)` | 音高较低，但方向 Standard 仍不足 |
| — | `masculine_continuous` | 以上均不满足 | `Final = Base` | 例如 `F0 < 145、N >= 50、S >= 50` |

### 5.1 加分公式

仅在第一条规则成立时计算：

```text
sF = (145 - F0) / 25
sN = (N - 80) / 20
sS = (S - 50) / 30
strength = min(sF, sN, sS, 1)
promoted = 60 + 40 * strength
Final = max(Base, promoted)
```

由于进入该分支前已保证三个条件分别大于阈值，`strength` 为正；其最大值被限制为 1。F0 对加分的贡献在 `120 Hz` 及以下达到最大，`F0 = 145 Hz` 时该分支不会触发。

### 5.2 边界值必须按实现理解

- `F0 = 145` 不属于低音高加分分支，会进入高音高分支；
- `N = 80` 不触发加分；`N = 50` 属于 `>= 50`；
- `S = 50` 不触发加分中的 `S > 50`，但也不满足 `S < 50` 的低音高封顶；
- 规则判断使用平均 F0，不使用中位数、5–95 百分位或单个瞬时帧；
- `Final` 最后仍会 `clamp(..., 0, 100)`。

## 6. F0 缺失或无效时

以下情况视为没有可用 F0：`nil`、非有限值（NaN / infinity）或 `<= 0`。

此时不计算 F0 贡献，也不套用任何 pitch 加分或封顶：

```text
Base  = S
Final = S
rule  = masculine_f0_unavailable
cap   = nil
```

这是“男性向 Standard 的方向分仍可显示，但缺少音高维度”的回退路径，不会伪造一个 F0，也不会把缺失值当成低音高。

## 7. iOS 端的保存、重算与展示

### 7.1 偏好选择与兼容

`VoicePreference` 有 `masculine / feminine / undecided` 三种值。读取偏好时兼容旧版中文字符串：`男性向声音`、`女性向声音`、`暂不确定`，同时接受新的语义 raw value。只有选择 `masculine` 时才走上述方向算法；女性向和暂不确定会保留 Core 原始结果。

### 7.2 结果页

`RecordingAnalysisView` 每次由当前 `VoicePreference` 调用 `preference.score(for: result)`，因此：

- 主分数使用 `directionScore.finalScore`；
- Standard 指标使用方向后的 `standardScore`；
- Naturalness 和语音时长保持原值；
- 公式页显示男性向的 `Standard = 100 - VFP`、反向 F0 公式和对应当前规则；
- 图表仍展示原始 VFP 的女性向百分比，并以 `100 - VFP` 显示男性向百分比。

图表中的音高频段只是频率描述，不是 composite 规则：

```text
very high:   F0 >= 255
feminine:    165 <= F0 < 255
androgynous: 145 <= F0 < 165
masculine:    85 <= F0 < 145
very low:    F0 < 85
```

### 7.3 SwiftData 历史记录

`RecordingAssessment` 保存的是不可变 Core 原始结果和输入快照：

- `standardScore` 保存原始 VFP；
- `naturalnessScore`、`meanPitchHz` 保存分析输入；
- `resultPayload` 保存完整 Core JSON；
- `recordedTargetRawValue`、`scoringRulesVersion` 保存当时的练习目标和规则版本；
- `capturedFinalScore` 保存当时目标方向的最终分（暂不确定不保存方向分）。

读取历史时，`finalScore(for: .masculine)` 会用保存的 VFP、自然度和 F0 再调用同一套男性向公式。因此切换用户偏好不会改写原始 JSON，也能重新显示旧录音的男性向分。

Insights 的 composite、每日最佳和趋势平均也通过 `assessment.finalScore(for: preference)` 使用当前方向。

### 7.4 导出报告的当前实现状态

当前 `RecordingExportView` 的 `ExportMetricOption.value` 只接收 `PitcheeAnalysisResult`，其中：

- `finalScore` 读取 `result.composite.finalScore`；
- `standardScore` 读取 `result.vfp.vfpStandardScore`；
- `baseScore` 读取 `result.composite.baseScore`。

这些字段是 Core 的原始女性向参考值，导出视图目前没有传入 `VoicePreference`，所以从男性向结果页打开导出时，报告中的分数项仍可能显示原始方向分。结果页和 Insights 已经按男性向重算；若要求导出也完全方向一致，需要让导出模型接收 `VoicePreference` 或 `VoiceDirectionScore`，并改用 `directionScore.finalScore / baseScore / standardScore`。这是当前代码的实现差异，不应在产品说明中写成“导出已统一”。

## 8. 实时 F0 与离线 F0 的关系

实时路径不自行计算男性向分数，只负责给录音期间的 pitch 图提供 F0：

- iOS 将麦克风数据转换为连续的 16 kHz 单声道 Float32；
- Core 实时流默认使用约 320 ms 上下文，按 256 samples hop 推理；
- Core 返回时间戳、F0 和 voiced/unvoiced 决策；
- `PitcheeCoreAnalyzer` actor 串行化实时推理和最终离线分析；
- 停止录音时先排空写盘和待处理实时任务，再用完整 WAV 做最终分析。

最终男性向分只使用离线分析结果中的全局平均 F0，实时曲线不会改变最终评分。

## 9. 一致性验证

### 9.1 Swift/C++ 交叉验证

执行：

```sh
./Scripts/test-voice-scoring.sh
```

该脚本：

1. 编译真实 C++ `scoring.cpp`，生成参考 TSV；
2. 用相同输入范围运行 Swift `VoiceDirectionScore.masculineComposite`；
3. 比较 base、final、cap、limited、boosted 和 rule；
4. 覆盖缺失 F0、阈值边界、加分、四种封顶和连续规则。

当前验证结果：`10,742 checks passed across 1,530 Core reference cases`。

### 9.2 历史与趋势验证

执行：

```sh
./Scripts/test-insights.sh
```

当前结果：`49 checks passed`，包含男性向方向分、缺失 F0 回退、每日最佳和切换方向后历史重算。

## 10. 关键限制与解释边界

- 男性向分是面向练习目标的方向性分数，不是性别识别结果、医学判断或发声健康诊断。
- 当前男性向算法主要由 VFP 补数、平均 F0、自然度和规则封顶构成；没有把共振峰、语速、韵律、辅音清晰度等指标加入 composite。
- 低音高本身不会保证高分：自然度不足会触发封顶，方向 Standard 不足也可能触发封顶。
- 缺失 F0 时只保留方向 Standard；不能据此推断用户音高表现。
- 变更阈值、权重、规则顺序或模型版本时，应提升 `rulesVersion` / 模型版本，并同步更新 Swift、C++、规则说明、导出和交叉测试。
