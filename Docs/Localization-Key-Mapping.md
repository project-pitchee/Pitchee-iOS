# 本地化键名映射表 (Localization key mapping)

本表与 `Resources/Localizable.xcstrings` 同步生成，共 **289** 个键。改名前每个键就是中文原文本身。

| 命名空间 (feature) | 键数量 |
| --- | --- |
| `export` | 81 |
| `analysis` | 70 |
| `scoring` | 40 |
| `recording` | 27 |
| `common` | 24 |
| `onboarding` | 14 |
| `voiceProfile` | 13 |
| `insights` | 8 |
| `settings` | 5 |
| `about` | 4 |
| `piano` | 3 |

## 全部键

| 新键 (new key) | 旧键 (was) | 简体中文 zh-Hans | English | 位置 |
| --- | --- | --- | --- | --- |
| `about.app.analysisEngine.label` | 分析引擎 | 分析引擎 | Analysis Engine | ContentView.swift:699, GeneratedStringSymbols_Localizable.swift:27 |
| `about.app.title` | 应用 | 应用 | App | ContentView.swift:697, GeneratedStringSymbols_Localizable.swift:36 |
| `about.app.version.label` | 版本 | 版本 | Version | ContentView.swift:698, GeneratedStringSymbols_Localizable.swift:45 |
| `about.screen.title` | 关于 | 关于 | About | ContentView.swift:109, ContentView.swift:702, GeneratedStringSymbols_Localizable.swift:54 |
| `analysis.emptyState.noResult.description` | 请返回录制，再录一段自然说话。 | 请返回录制，再录一段自然说话。 | Go back to recording and record another sample of natural speech. | GeneratedStringSymbols_Localizable.swift:63, RecordingAnalysisView.swift:29 |
| `analysis.emptyState.noResult.title` | 这次没有完成分析 | 这次没有完成分析 | This Analysis Wasn't Completed | GeneratedStringSymbols_Localizable.swift:72, RecordingAnalysisView.swift:27 |
| `analysis.error.analysisFailed %lld` | 分析失败（E-\(coreError.statusCode)），请再录一段音频试试。 | 分析失败（E-%1$lld），请再录一段音频试试。 | Analysis failed (E-%1$lld). Record another clip and try again. | AnalysisViewModel.swift:335, GeneratedStringSymbols_Localizable.swift:81 |
| `analysis.error.modelUnavailable %lld` | 分析模型暂时不可用（E-\(coreError.statusCode)），请重启应用后再试。 | 分析模型暂时不可用（E-%1$lld），请重启应用后再试。 | The analysis model is temporarily unavailable (E-%1$lld). Restart the app and try again. | AnalysisViewModel.swift:331, GeneratedStringSymbols_Localizable.swift:90 |
| `analysis.error.noSpeechDetected` | 没有检测到人声，请录一段更清晰、包含连续说话的音频。 | 没有检测到人声，请录一段更清晰、包含连续说话的音频。 | No speech was detected. Please record a clearer clip with continuous speech. | AnalysisViewModel.swift:329, GeneratedStringSymbols_Localizable.swift:99 |
| `analysis.error.recordingUnreadable %lld` | 录音格式无法读取（E-\(coreError.statusCode)），请重新录制。 | 录音格式无法读取（E-%1$lld），请重新录制。 | The recording format couldn't be read (E-%1$lld). Please record again. | AnalysisViewModel.swift:333, GeneratedStringSymbols_Localizable.swift:108 |
| `analysis.error.resultSaveFailed` | 测评已完成，但结果未能保存。请检查设备存储空间后再试。 | 测评已完成，但结果未能保存。请检查设备存储空间后再试。 | The assessment finished, but the result couldn't be saved. Check your device's storage and try again. | AnalysisViewModel.swift:282, GeneratedStringSymbols_Localizable.swift:117, RecordingAnalysisView.swift:1207 |
| `analysis.error.resultUnreadable` | 分析结果无法读取（E-JSON），请稍后再试。 | 分析结果无法读取（E-JSON），请稍后再试。 | The analysis result couldn't be read (E-JSON). Please try again later. | AnalysisViewModel.swift:324, GeneratedStringSymbols_Localizable.swift:126 |
| `analysis.navigation.analyzing` | 正在分析 | 正在分析 | Analyzing | GeneratedStringSymbols_Localizable.swift:135, RecordingAnalysisView.swift:37 |
| `analysis.navigation.result` | 结果 | 结果 | Result | GeneratedStringSymbols_Localizable.swift:144, RecordingAnalysisView.swift:38 |
| `analysis.pitchBands.androgynous` | 中性 | 中性 | Neutral | GeneratedStringSymbols_Localizable.swift:153, RecordingAnalysisView.swift:552 |
| `analysis.pitchBands.feminine` | 女性 | 女性 | Feminine | GeneratedStringSymbols_Localizable.swift:162, RecordingAnalysisView.swift:551 |
| `analysis.pitchBands.masculine` | 男性 | 男性 | Masculine | GeneratedStringSymbols_Localizable.swift:171, RecordingAnalysisView.swift:553 |
| `analysis.pitchBands.veryHigh` | 很高 | 很高 | Very High | GeneratedStringSymbols_Localizable.swift:180, RecordingAnalysisView.swift:550 |
| `analysis.pitchBands.veryLow` | 很低 | 很低 | Very Low | GeneratedStringSymbols_Localizable.swift:189, RecordingAnalysisView.swift:554 |
| `analysis.pitchScale.averageMarker` | AVG | 平均 | AVG | GeneratedStringSymbols_Localizable.swift:198, RecordingAnalysisView.swift:1089 |
| `analysis.pitchScale.maxLabel` | 350 Hz | 350 Hz | 350 Hz | GeneratedStringSymbols_Localizable.swift:207, RecordingAnalysisView.swift:1045 |
| `analysis.pitchScale.minLabel` | 50 Hz | 50 Hz | 50 Hz | GeneratedStringSymbols_Localizable.swift:216, RecordingAnalysisView.swift:1103 |
| `analysis.progress.privacyNote` | 声音留在你的设备上 | 声音留在你的设备上 | Your voice stays on your device | GeneratedStringSymbols_Localizable.swift:225, RecordingAnalysisView.swift:81 |
| `analysis.progress.subtitle` | 正在设备上分析音高与声音特征。\n首次分析可能需要一点时间。 | 正在设备上分析音高与声音特征。\n首次分析可能需要一点时间。 | Analyzing pitch and voice features on your device.\nThe first analysis may take a little while. | GeneratedStringSymbols_Localizable.swift:234, RecordingAnalysisView.swift:76 |
| `analysis.progress.title` | 正在听懂你的声音 | 正在听懂你的声音 | Listening to Your Voice | GeneratedStringSymbols_Localizable.swift:243, RecordingAnalysisView.swift:74 |
| `analysis.resourceDetail.article.title` | 文章 | 文章 | Article | GeneratedStringSymbols_Localizable.swift:252, RecordingAnalysisView.swift:911 |
| `analysis.resourceDetail.video.title` | 视频 | 视频 | Video | GeneratedStringSymbols_Localizable.swift:261, RecordingAnalysisView.swift:912 |
| `analysis.resources.naturalnessTraining.description` | 用一段短练习找到更放松的语气，再回到录音页试一次。 | 用一段短练习找到更放松的语气，再回到录音页试一次。 | Use a short exercise to find a more relaxed tone, then go back to the recording screen and try again. | GeneratedStringSymbols_Localizable.swift:270, RecordingAnalysisView.swift:367 |
| `analysis.resources.naturalnessTraining.subtitle` | 视频练习 · 放松与连贯表达 | 视频练习 · 放松与连贯表达 | Video exercise · Relaxation and connected speech | GeneratedStringSymbols_Localizable.swift:279, RecordingAnalysisView.swift:363 |
| `analysis.resources.naturalnessTraining.title` | 自然度训练 | 自然度训练 | Naturalness Training | GeneratedStringSymbols_Localizable.swift:288, RecordingAnalysisView.swift:362 |
| `analysis.resources.readBadge` | 阅读 | 阅读 | Read | GeneratedStringSymbols_Localizable.swift:297, RecordingAnalysisView.swift:373 |
| `analysis.resources.subtitle` | 把建议带到下一次练习里 | 把建议带到下一次练习里 | Take these suggestions into your next practice | GeneratedStringSymbols_Localizable.swift:306, RecordingAnalysisView.swift:270 |
| `analysis.resources.title` | 练习资源 | 练习资源 | Practice Resources | GeneratedStringSymbols_Localizable.swift:315, RecordingAnalysisView.swift:268 |
| `analysis.resources.voiceResearch.description` | 了解音高、自然度与录音条件之间的关系，把结果当成长期练习的参考。 | 了解音高、自然度与录音条件之间的关系，把结果当成长期练习的参考。 | Learn how pitch, naturalness, and recording conditions relate to each other, and treat the results as a long-term practice reference. | GeneratedStringSymbols_Localizable.swift:324, RecordingAnalysisView.swift:376 |
| `analysis.resources.voiceResearch.subtitle` | 文章 · 了解音高与自然度 | 文章 · 了解音高与自然度 | Article · Understanding pitch and naturalness | GeneratedStringSymbols_Localizable.swift:333, RecordingAnalysisView.swift:372 |
| `analysis.resources.voiceResearch.title` | 声音研究 | 声音研究 | Voice Research | GeneratedStringSymbols_Localizable.swift:342, RecordingAnalysisView.swift:371 |
| `analysis.score.explanation.a11y` | 查看评分如何得出 | 查看评分如何得出 | See how the score is calculated | GeneratedStringSymbols_Localizable.swift:351, RecordingAnalysisView.swift:428 |
| `analysis.score.headlineHigh` | 这次表现很亮眼，继续保持稳定的表达。 | 这次表现很亮眼，继续保持稳定的表达。 | This take stands out — keep your delivery steady. | GeneratedStringSymbols_Localizable.swift:360, RecordingAnalysisView.swift:466 |
| `analysis.score.headlineLow` | 把下面的一条建议带到下一次录音里，结果会更有参考价值。 | 把下面的一条建议带到下一次录音里，结果会更有参考价值。 | Take one suggestion below into your next recording to get more useful results. | GeneratedStringSymbols_Localizable.swift:369, RecordingAnalysisView.swift:468 |
| `analysis.score.headlineMedium` | 基础表现不错，针对下面的建议再练一次。 | 基础表现不错，针对下面的建议再练一次。 | A solid foundation — run through it again with the suggestions below. | GeneratedStringSymbols_Localizable.swift:378, RecordingAnalysisView.swift:467 |
| `analysis.score.progress.a11y` | 综合评分进度 | 综合评分进度 | Overall score progress | GeneratedStringSymbols_Localizable.swift:387, RecordingAnalysisView.swift:448 |
| `analysis.score.progress.a11yValue %@` | \(scoreText(result.composite.finalScore)) 分，共 100 分 | %1$@ 分，共 100 分 | %1$@ out of 100 points | GeneratedStringSymbols_Localizable.swift:396, RecordingAnalysisView.swift:449 |
| `analysis.score.summary.a11y %@` | 综合评分 \(scoreText(result.composite.finalScore)) 分，满分 100 分 | 综合评分 %1$@ 分，满分 100 分 | Overall score %1$@ out of 100 | GeneratedStringSymbols_Localizable.swift:405, RecordingAnalysisView.swift:457 |
| `analysis.statistics.averageVolume.label` | 平均音量 | 平均音量 | Average Volume | GeneratedStringSymbols_Localizable.swift:414, RecordingAnalysisView.swift:504 |
| `analysis.statistics.dominantPitchBand.label` | 主要音域 | 主要音域 | Dominant Pitch Band | GeneratedStringSymbols_Localizable.swift:423, RecordingAnalysisView.swift:497 |
| `analysis.statistics.medianVolume.label` | 中位音量 | 中位音量 | Median Volume | GeneratedStringSymbols_Localizable.swift:432, RecordingAnalysisView.swift:505 |
| `analysis.statistics.pitch.title` | Pitch | 音高 | Pitch | GeneratedStringSymbols_Localizable.swift:441, RecordingAnalysisView.swift:474 |
| `analysis.statistics.volume.note` | 音量使用 dBFS 表示，0 dBFS 为设备可记录的最大值；平均值和中位数下方显示高于环境底噪的音量。 | 音量使用 dBFS 表示，0 dBFS 为设备可记录的最大值；平均值和中位数下方显示高于环境底噪的音量。 | Volume is shown in dBFS, where 0 dBFS is the loudest level the device can record; the values shown under average and median are volume above the ambient noise floor. | GeneratedStringSymbols_Localizable.swift:450, RecordingAnalysisView.swift:478 |
| `analysis.statistics.volume.title` | Volume | 音量 | Volume | GeneratedStringSymbols_Localizable.swift:459, RecordingAnalysisView.swift:476 |
| `analysis.statistics.volumeRange.label` | 音量范围 | 音量范围 | Volume Range | GeneratedStringSymbols_Localizable.swift:468, RecordingAnalysisView.swift:506 |
| `analysis.suggestionDetail.title` | 练习建议 | 练习建议 | Practice Suggestion | GeneratedStringSymbols_Localizable.swift:477, RecordingAnalysisView.swift:866 |
| `analysis.suggestions.adequateRecording.description` | 你已经提供了足够的语音信息。下次保持相近时长，趋势会更容易看懂。 | 你已经提供了足够的语音信息。下次保持相近时长，趋势会更容易看懂。 | You already gave enough voice data. Keep a similar length next time and the trend will be easier to read. | GeneratedStringSymbols_Localizable.swift:486, RecordingAnalysisView.swift:341 |
| `analysis.suggestions.adequateRecording.subtitle` | 继续用相近时长录制，方便比较每次变化。 | 继续用相近时长录制，方便比较每次变化。 | Keep recording for a similar length so each change is easy to compare. | GeneratedStringSymbols_Localizable.swift:495, RecordingAnalysisView.swift:336 |
| `analysis.suggestions.adequateRecording.title` | 保持相近的录音时长 | 保持相近的录音时长 | Keep a Similar Recording Length | GeneratedStringSymbols_Localizable.swift:504, RecordingAnalysisView.swift:333 |
| `analysis.suggestions.naturalSpeech.description` | 自然度是一个参考值。保持轻松的语速和连贯的呼吸，比追求单次分数更有帮助。 | 自然度是一个参考值。保持轻松的语速和连贯的呼吸，比追求单次分数更有帮助。 | Naturalness is only a reference value. An easy pace and steady breathing help more than chasing a single score. | GeneratedStringSymbols_Localizable.swift:513, RecordingAnalysisView.swift:353 |
| `analysis.suggestions.naturalSpeech.subtitle` | 这次自然度表现不错，保持放松和连贯的表达。 | 这次自然度表现不错，保持放松和连贯的表达。 | Naturalness looked good this time; stay relaxed and keep your delivery connected. | GeneratedStringSymbols_Localizable.swift:522, RecordingAnalysisView.swift:348 |
| `analysis.suggestions.naturalSpeech.title` | 继续保持自然语气 | 继续保持自然语气 | Keep Your Natural Tone | GeneratedStringSymbols_Localizable.swift:531, RecordingAnalysisView.swift:345 |
| `analysis.suggestions.shortRecording.description` | 试着连续说 10 秒以上的自然句子。录音更完整，音高和自然度的估计会更稳定。 | 试着连续说 10 秒以上的自然句子。录音更完整，音高和自然度的估计会更稳定。 | Try speaking natural sentences continuously for 10 seconds or more. A more complete recording gives more stable pitch and naturalness estimates. | GeneratedStringSymbols_Localizable.swift:540, RecordingAnalysisView.swift:340 |
| `analysis.suggestions.shortRecording.subtitle` | 有效语音不足 5 秒，更多声音信息会让结果更稳定。 | 有效语音不足 5 秒，更多声音信息会让结果更稳定。 | Less than 5 seconds of effective speech; more voice data makes the result more stable. | GeneratedStringSymbols_Localizable.swift:549, RecordingAnalysisView.swift:335 |
| `analysis.suggestions.shortRecording.title` | 下次多录一会儿 | 下次多录一会儿 | Record a Bit Longer Next Time | GeneratedStringSymbols_Localizable.swift:558, RecordingAnalysisView.swift:333 |
| `analysis.suggestions.subtitle` | 根据这次录音，下一步可以这样练习 | 根据这次录音，下一步可以这样练习 | Based on this recording, here is what to practice next | GeneratedStringSymbols_Localizable.swift:567, RecordingAnalysisView.swift:212 |
| `analysis.suggestions.title` | 建议 | 建议 | Suggestions | GeneratedStringSymbols_Localizable.swift:576, RecordingAnalysisView.swift:210 |
| `analysis.suggestions.unnaturalSpeech.description` | 先放松下颌和肩膀，用熟悉的句子练习。不要刻意压低或抬高音高，先让表达保持连贯。 | 先放松下颌和肩膀，用熟悉的句子练习。不要刻意压低或抬高音高，先让表达保持连贯。 | Relax your jaw and shoulders first and practise with familiar sentences. Don't force your pitch up or down — focus on keeping your delivery connected. | GeneratedStringSymbols_Localizable.swift:585, RecordingAnalysisView.swift:352 |
| `analysis.suggestions.unnaturalSpeech.subtitle` | 放慢语速，保持连续呼吸，再试着说一段熟悉的话。 | 放慢语速，保持连续呼吸，再试着说一段熟悉的话。 | Slow down, keep breathing steadily, and try a familiar passage. | GeneratedStringSymbols_Localizable.swift:594, RecordingAnalysisView.swift:347 |
| `analysis.suggestions.unnaturalSpeech.title` | 让语气更自然 | 让语气更自然 | Make Your Tone More Natural | GeneratedStringSymbols_Localizable.swift:603, RecordingAnalysisView.swift:345 |
| `analysis.voiceDetails.action` | 声音详情 | 声音详情 | Voice Details | GeneratedStringSymbols_Localizable.swift:612, RecordingAnalysisView.swift:159 |
| `analysis.voiceDetails.action.a11y` | 查看声音详情 | 查看声音详情 | View voice details | GeneratedStringSymbols_Localizable.swift:621, RecordingAnalysisView.swift:167 |
| `analysis.voiceDetails.metrics.title` | 声音指标 | 声音指标 | Voice Metrics | GeneratedStringSymbols_Localizable.swift:630, RecordingAnalysisView.swift:386 |
| `analysis.voiceDetails.title` | 声音详情 | 声音详情 | Voice Details | GeneratedStringSymbols_Localizable.swift:639, RecordingAnalysisView.swift:402 |
| `analysis.voiceProfile.female.label` | Female | 女性 | Female | GeneratedStringSymbols_Localizable.swift:648, RecordingAnalysisView.swift:948 |
| `analysis.voiceProfile.male.label` | Male | 男性 | Male | GeneratedStringSymbols_Localizable.swift:657, RecordingAnalysisView.swift:949 |
| `analysis.voiceProfile.noData` | 无可靠数据 | 无可靠数据 | No Reliable Data | GeneratedStringSymbols_Localizable.swift:666, RecordingAnalysisView.swift:999, RecordingAnalysisView.swift:1004 |
| `analysis.voiceProfile.reference.a11y %@ %@ %@ %@` | 声音倾向参考，平均音高 \(meanPitchText)，样本音高范围 \(pitchRangeText)，Female \(percentageText(femaleValue))，Male \(percentageText(maleValue)) | 声音倾向参考，平均音高 %1$@，样本音高范围 %2$@，Female %3$@，Male %4$@ | Voice tendency reference: average pitch %1$@, sample pitch range %2$@, Female %3$@, Male %4$@ | GeneratedStringSymbols_Localizable.swift:675, RecordingAnalysisView.swift:966 |
| `analysis.voiceProfile.title` | 声音倾向参考 | 声音倾向参考 | Voice Tendency Reference | GeneratedStringSymbols_Localizable.swift:684, RecordingAnalysisView.swift:150 |
| `common.action.done` | 完成 | 完成 | Done | GeneratedStringSymbols_Localizable.swift:693, PitchImageExportButton.swift:61, RecordingAnalysisView.swift:406, RecordingAnalysisView.swift:870 |
| `common.action.ok` | 好 | 好 | OK | GeneratedStringSymbols_Localizable.swift:702, PitchImageExportButton.swift:28, PitchImageExportButton.swift:91, RecordingExportView.swift:119 |
| `common.brand.name` |  | Pitchee | Pitchee | GeneratedStringSymbols_Localizable.swift:711, LivePitchChartView.swift:122 |
| `common.brand.wordmark` | PITCHEE | PITCHEE | PITCHEE | GeneratedStringSymbols_Localizable.swift:720, OnboardingView.swift:101 |
| `common.error.tryAgainLater` | 请稍后再试。 | 请稍后再试。 | Please try again later. | GeneratedStringSymbols_Localizable.swift:729, PitchImageExportButton.swift:30, PitchImageExportButton.swift:93, RecordingExportView.swift:121 |
| `common.metric.compositeScore.title` | 综合评分 | 综合评分 | Overall Score | ContentView.swift:150, GeneratedStringSymbols_Localizable.swift:738, RecordingAnalysisView.swift:416, RecordingExportView.swift:449 |
| `common.metric.corePitchRange.title` | 核心音域 | 核心音域 | Core Pitch Range | GeneratedStringSymbols_Localizable.swift:747, RecordingAnalysisView.swift:496, RecordingExportView.swift:443 |
| `common.metric.environmentNoiseFloor.title` | 环境底噪 | 环境底噪 | Ambient Noise Floor | GeneratedStringSymbols_Localizable.swift:756, RecordingAnalysisView.swift:503, RecordingExportView.swift:445 |
| `common.metric.meanPitch.title` | 平均音高 | 平均音高 | Average Pitch | ContentView.swift:170, GeneratedStringSymbols_Localizable.swift:765, RecordingAnalysisView.swift:494, RecordingExportView.swift:440 |
| `common.metric.medianPitch.title` | 中位音高 | 中位音高 | Median Pitch | GeneratedStringSymbols_Localizable.swift:774, RecordingAnalysisView.swift:495, RecordingExportView.swift:441 |
| `common.metric.naturalness.title` | 自然度 | 自然度 | Naturalness | ContentView.swift:160, GeneratedStringSymbols_Localizable.swift:783, RecordingAnalysisView.swift:389, RecordingExportView.swift:451 |
| `common.metric.speechDuration.title` | 有效语音 | 有效语音 | Voiced Speech | ContentView.swift:180, GeneratedStringSymbols_Localizable.swift:792, RecordingAnalysisView.swift:391, RecordingExportView.swift:437 |
| `common.metric.standardScore.title` | 标准评分 | 标准评分 | Standard Score | GeneratedStringSymbols_Localizable.swift:801, RecordingAnalysisView.swift:390, RecordingExportView.swift:450 |
| `common.placeholder.noValue` | — | — | — | ContentView.swift:134, GeneratedStringSymbols_Localizable.swift:810, RecordingAnalysisView.swift:535, RecordingAnalysisView.swift:541 |
| `common.unit.channels` | 声道 | 声道 | channels | GeneratedStringSymbols_Localizable.swift:819, RecordingExportView.swift:500 |
| `common.unit.count` | 个 | 个 | windows | GeneratedStringSymbols_Localizable.swift:828, RecordingExportView.swift:510 |
| `common.unit.days` | 天 | 天 | days | ContentView.swift:288, GeneratedStringSymbols_Localizable.swift:837 |
| `common.unit.dbfs` | dBFS | dBFS | dBFS | GeneratedStringSymbols_Localizable.swift:846, RecordingAnalysisView.swift:503, RecordingAnalysisView.swift:565, RecordingExportView.swift:512 |
| `common.unit.dbfsPercentileRange` | dBFS · 5–95% | dBFS · 5–95% | dBFS · 5–95% | GeneratedStringSymbols_Localizable.swift:855, RecordingAnalysisView.swift:506, RecordingExportView.swift:520 |
| `common.unit.dbfsWithDelta %@` | dBFS · \(delta) dB | dBFS · %1$@ dB | dBFS · %1$@ dB | GeneratedStringSymbols_Localizable.swift:864, RecordingAnalysisView.swift:571 |
| `common.unit.hertz` | Hz | Hz | Hz | ContentView.swift:580, GeneratedStringSymbols_Localizable.swift:873, RecordingAnalysisView.swift:494, RecordingAnalysisView.swift:495 |
| `common.unit.hertzPercentileRange` | Hz · 5–95% | Hz · 5–95% | Hz · 5–95% | GeneratedStringSymbols_Localizable.swift:882, RecordingAnalysisView.swift:496, RecordingExportView.swift:508 |
| `common.unit.pointsOutOf100` | / 100 | / 100 | / 100 | GeneratedStringSymbols_Localizable.swift:891, RecordingAnalysisView.swift:389, RecordingAnalysisView.swift:390, RecordingAnalysisView.swift:439 |
| `common.unit.seconds` | 秒 | 秒 | sec | GeneratedStringSymbols_Localizable.swift:900, RecordingAnalysisView.swift:391, RecordingExportView.swift:492, RecordingExportView.swift:494 |
| `export.chart.backgroundLoudness.legend` | 背景响度 | 背景响度 | Background Loudness | GeneratedStringSymbols_Localizable.swift:909, RecordingExportView.swift:1052 |
| `export.chart.backgroundLoudness.note` | 曲线显示未检测到语音时的环境底噪，单位为 dBFS。 | 曲线显示未检测到语音时的环境底噪，单位为 dBFS。 | The curve shows the ambient noise floor while no speech was detected, in dBFS. | GeneratedStringSymbols_Localizable.swift:918, RecordingExportView.swift:1078 |
| `export.chart.backgroundLoudnessCurve.title` | 背景响度曲线 | 背景响度曲线 | Background Loudness Curve | GeneratedStringSymbols_Localizable.swift:927, RecordingExportView.swift:1068 |
| `export.chart.combinedCurves.title` | 声音曲线 | 声音曲线 | Sound Curves | GeneratedStringSymbols_Localizable.swift:936, RecordingExportView.swift:1068 |
| `export.chart.frequency.legend` | 频率 | 频率 | Frequency | GeneratedStringSymbols_Localizable.swift:945, RecordingExportView.swift:1050 |
| `export.chart.frequencyCurve.title` | 频率曲线 | 频率曲线 | Frequency Curve | GeneratedStringSymbols_Localizable.swift:954, RecordingExportView.swift:1068 |
| `export.chart.loudnessCurve.title` | 响度曲线 | 响度曲线 | Loudness Curve | GeneratedStringSymbols_Localizable.swift:963, RecordingExportView.swift:1068 |
| `export.chart.loudnessScale.note` | 语音响度与背景响度以 dBFS 表示，数值越接近 0 越响。 | 语音响度与背景响度以 dBFS 表示，数值越接近 0 越响。 | Voice and background loudness are shown in dBFS; values closer to 0 are louder. | GeneratedStringSymbols_Localizable.swift:972, RecordingExportView.swift:1076 |
| `export.chart.multiCurveGap.note` | 曲线空白处表示该时间段没有可靠检测结果；三条曲线共用同一时间轴。 | 曲线空白处表示该时间段没有可靠检测结果；三条曲线共用同一时间轴。 | Gaps in the curves mean no reliable result for that time range; all curves share the same time axis. | GeneratedStringSymbols_Localizable.swift:981, RecordingExportView.swift:1073 |
| `export.chart.pitchGap.note` | 曲线空白处表示未检测到可靠音高。 | 曲线空白处表示未检测到可靠音高。 | Gaps in the curve mean no reliable pitch was detected. | GeneratedStringSymbols_Localizable.swift:990, RecordingExportView.swift:1075 |
| `export.chart.result.caption` | 圆形大小表示声音倾向参考占比；左侧刻度显示平均音高与核心音域。 | 圆形大小表示声音倾向参考占比；左侧刻度显示平均音高与核心音域。 | Circle size shows the reference share of voice tendency; the left scale shows mean pitch and core pitch range. | GeneratedStringSymbols_Localizable.swift:999, RecordingExportView.swift:1138 |
| `export.chart.timeAxis.label` | 时间 / 秒 | 时间 / 秒 | Time / s | GeneratedStringSymbols_Localizable.swift:1008, RecordingExportView.swift:919 |
| `export.chart.voiceLoudness.legend` | 语音响度 | 语音响度 | Voice Loudness | GeneratedStringSymbols_Localizable.swift:1017, RecordingExportView.swift:1051 |
| `export.chart.voiceLoudness.note` | 曲线显示检测到语音时的响度，单位为 dBFS。 | 曲线显示检测到语音时的响度，单位为 dBFS。 | The curve shows loudness while speech was detected, in dBFS. | GeneratedStringSymbols_Localizable.swift:1026, RecordingExportView.swift:1077 |
| `export.entry.openExport` | 导出 | 导出 | Export | GeneratedStringSymbols_Localizable.swift:1035, RecordingExportView.swift:20 |
| `export.error.imageGenerationFailed` | 图片生成失败，请稍后重试。 | 图片生成失败，请稍后重试。 | Couldn't create the image. Please try again later. | GeneratedStringSymbols_Localizable.swift:1044, PitchImageExportButton.swift:16, RecordingExportView.swift:221 |
| `export.error.imageSaveFailed.message` | 图片未能保存，请检查存储空间后重试。 | 图片未能保存，请检查存储空间后重试。 | The image couldn't be saved. Check your available storage and try again. | GeneratedStringSymbols_Localizable.swift:1053, PitchImageExportButton.swift:85, RecordingExportView.swift:233 |
| `export.error.imageSaveFailed.title` | 无法保存图片 | 无法保存图片 | Can't Save Image | GeneratedStringSymbols_Localizable.swift:1062, PitchImageExportButton.swift:24, PitchImageExportButton.swift:87 |
| `export.error.nothingToExport` | 没有可导出的内容。 | 没有可导出的内容。 | There's nothing to export. | GeneratedStringSymbols_Localizable.swift:1071, RecordingExportView.swift:207 |
| `export.error.photoLibraryAccessDenied.message` |  | 无法向相册添加图片。请在系统设置中检查 Pitchee 的照片权限后重试。 | Can't add images to your photo library. Check Pitchee’s photo permissions in Settings and try again. | GeneratedStringSymbols_Localizable.swift:1080, RecordingExportView.swift:217 |
| `export.error.reportSaveFailed.message` | 报告未能保存，请检查存储空间后重试。 | 报告未能保存，请检查存储空间后重试。 | The report couldn't be saved. Check your available storage and try again. | GeneratedStringSymbols_Localizable.swift:1089, RecordingExportView.swift:112, RecordingExportView.swift:237 |
| `export.error.reportSaveFailed.title` | 无法导出报告 | 无法导出报告 | Couldn't Export Report | GeneratedStringSymbols_Localizable.swift:1098, RecordingExportView.swift:115 |
| `export.format.image` |  | 图像 | Image | GeneratedStringSymbols_Localizable.swift:1107, RecordingExportView.swift:298 |
| `export.format.label` |  | 导出方式 | Export Format | GeneratedStringSymbols_Localizable.swift:1116, RecordingExportView.swift:54 |
| `export.format.pdf` |  | PDF | PDF | GeneratedStringSymbols_Localizable.swift:1125, RecordingExportView.swift:299 |
| `export.metric.analyzedDuration.title` | 分析时长 | 分析时长 | Analyzed Length | GeneratedStringSymbols_Localizable.swift:1134, RecordingExportView.swift:436 |
| `export.metric.averageLoudness.title` | 平均响度 | 平均响度 | Average Loudness | GeneratedStringSymbols_Localizable.swift:1143, RecordingExportView.swift:446 |
| `export.metric.baseScore.title` | 基础评分 | 基础评分 | Base Score | GeneratedStringSymbols_Localizable.swift:1152, RecordingExportView.swift:452 |
| `export.metric.channels.title` | 声道 | 声道 | Channels | GeneratedStringSymbols_Localizable.swift:1161, RecordingExportView.swift:439 |
| `export.metric.detail.audioFormat` | 原始音频格式 | 原始音频格式 | Original audio format | GeneratedStringSymbols_Localizable.swift:1170, RecordingExportView.swift:461 |
| `export.metric.detail.loudness` | 语音与环境音量，单位 dBFS | 语音与环境音量，单位 dBFS | Speech and ambient loudness, in dBFS | GeneratedStringSymbols_Localizable.swift:1179, RecordingExportView.swift:465 |
| `export.metric.detail.pitch` | 从可靠音高窗口计算 | 从可靠音高窗口计算 | Calculated from reliable pitch windows | GeneratedStringSymbols_Localizable.swift:1188, RecordingExportView.swift:463 |
| `export.metric.detail.score` | 本次分析评分，满分 100 | 本次分析评分，满分 100 | Scores from this analysis, out of 100 | GeneratedStringSymbols_Localizable.swift:1197, RecordingExportView.swift:467 |
| `export.metric.detail.timing` | 录音文件中的时间信息 | 录音文件中的时间信息 | Timing information from the recording file | GeneratedStringSymbols_Localizable.swift:1206, RecordingExportView.swift:459 |
| `export.metric.inputDuration.title` | 录音时长 | 录音时长 | Recording Length | GeneratedStringSymbols_Localizable.swift:1215, RecordingExportView.swift:435 |
| `export.metric.loudnessRange.title` | 响度范围 | 响度范围 | Loudness Range | GeneratedStringSymbols_Localizable.swift:1224, RecordingExportView.swift:448 |
| `export.metric.medianLoudness.title` | 中位响度 | 中位响度 | Median Loudness | GeneratedStringSymbols_Localizable.swift:1233, RecordingExportView.swift:447 |
| `export.metric.pitchStandardDeviation.title` | 音高标准差 | 音高标准差 | Pitch Standard Deviation | GeneratedStringSymbols_Localizable.swift:1242, RecordingExportView.swift:442 |
| `export.metric.sampleRate.title` | 采样率 | 采样率 | Sample Rate | GeneratedStringSymbols_Localizable.swift:1251, RecordingExportView.swift:438 |
| `export.metric.valueRange %@ %@` | \(number(low))–\(number(high)) | %1$@–%2$@ | %1$@–%2$@ | GeneratedStringSymbols_Localizable.swift:1260, RecordingExportView.swift:540 |
| `export.metric.voicedWindows.title` | 有效音高窗口 | 有效音高窗口 | Voiced Pitch Windows | GeneratedStringSymbols_Localizable.swift:1269, RecordingExportView.swift:444 |
| `export.metricGroup.loudness` | 响度 | 响度 | Loudness | GeneratedStringSymbols_Localizable.swift:1278, RecordingExportView.swift:392 |
| `export.metricGroup.pitch` | 音高 | 音高 | Pitch | GeneratedStringSymbols_Localizable.swift:1287, RecordingExportView.swift:391 |
| `export.metricGroup.recording` | 录音指标 | 录音指标 | Recording Metrics | GeneratedStringSymbols_Localizable.swift:1296, RecordingExportView.swift:390 |
| `export.metricGroup.result` | 结果 | 结果 | Results | GeneratedStringSymbols_Localizable.swift:1305, RecordingExportView.swift:393 |
| `export.photos.saved.message` |  | 所有预览页均已保存到相册。 | All preview pages have been saved to your photo library. | GeneratedStringSymbols_Localizable.swift:1314, RecordingExportView.swift:126 |
| `export.photos.saved.title` |  | 已保存到相册 | Saved to Photos | GeneratedStringSymbols_Localizable.swift:1323, RecordingExportView.swift:123 |
| `export.pitchImage.chart.duration %@` | 时长 \(timeline.duration.formatted(.number.precision(.fractionLength(1)))) 秒 · F0 / Hz | 时长 %1$@ 秒 · F0 / Hz | Duration: %1$@ s · F0 / Hz | GeneratedStringSymbols_Localizable.swift:1332, LivePitchChartView.swift:118 |
| `export.pitchImage.chart.gapNote` | 曲线空白处表示未检测到可靠音高。 | 曲线空白处表示未检测到可靠音高。 | Gaps in the curve mean no reliable pitch was detected. | GeneratedStringSymbols_Localizable.swift:1341, LivePitchChartView.swift:128 |
| `export.pitchImage.chart.title` | 完整音高曲线 | 完整音高曲线 | Full Pitch Curve | GeneratedStringSymbols_Localizable.swift:1350, LivePitchChartView.swift:117 |
| `export.pitchImage.preview.a11y` | 完整音高曲线图片 | 完整音高曲线图片 | Full pitch curve image | GeneratedStringSymbols_Localizable.swift:1359, PitchImageExportButton.swift:53 |
| `export.pitchImage.saveChart` | 保存完整音高图 | 保存完整音高图 | Save Full Pitch Chart | GeneratedStringSymbols_Localizable.swift:1368, PitchImageExportButton.swift:11 |
| `export.pitchImage.saveToFiles` | 存储到文件 | 存储到文件 | Save to Files | GeneratedStringSymbols_Localizable.swift:1377, PitchImageExportButton.swift:66 |
| `export.pitchImage.share` | 保存或分享 | 保存或分享 | Save or Share | GeneratedStringSymbols_Localizable.swift:1386, PitchImageExportButton.swift:72 |
| `export.pitchImage.share.subject` | 完整音高图 | 完整音高图 | Full Pitch Chart | GeneratedStringSymbols_Localizable.swift:1395, PitchImageExportButton.swift:70 |
| `export.pitchImage.sheet.title` | 完整音高图 | 完整音高图 | Full Pitch Chart | GeneratedStringSymbols_Localizable.swift:1404, PitchImageExportButton.swift:57 |
| `export.preview.heading` | 预览 | 预览 | Preview | GeneratedStringSymbols_Localizable.swift:1413, RecordingExportView.swift:157 |
| `export.preview.nextPage` | 下一页 | 下一页 | Next | GeneratedStringSymbols_Localizable.swift:1422 |
| `export.preview.pageIndicator %lld %lld` | A4 · \(safePageIndex + 1) / \(pageModels.count) | A4 · %1$lld / %2$lld | A4 · %1$lld / %2$lld | GeneratedStringSymbols_Localizable.swift:1431, RecordingExportView.swift:180 |
| `export.preview.previousPage` | 上一页 | 上一页 | Previous | GeneratedStringSymbols_Localizable.swift:1440 |
| `export.report.brandName` | Pitchee | Pitchee | Pitchee | GeneratedStringSymbols_Localizable.swift:1449, RecordingExportView.swift:778 |
| `export.report.charts` | 图表 | 图表 | Charts | GeneratedStringSymbols_Localizable.swift:1458, RecordingExportView.swift:787 |
| `export.report.data` | 数据 | 数据 | Data | GeneratedStringSymbols_Localizable.swift:1467, RecordingExportView.swift:809 |
| `export.report.emptyState.message` | 回到导出页选择图表或数据。 | 回到导出页选择图表或数据。 | Return to the export screen and select charts or data. | GeneratedStringSymbols_Localizable.swift:1476, RecordingExportView.swift:846 |
| `export.report.emptyState.title` | 没有选择导出内容 | 没有选择导出内容 | Nothing Selected for Export | GeneratedStringSymbols_Localizable.swift:1485, RecordingExportView.swift:843 |
| `export.report.footer` | Pitchee · 声音分析 | Pitchee · 声音分析 | Pitchee · Sound Analysis | GeneratedStringSymbols_Localizable.swift:1494, RecordingExportView.swift:744 |
| `export.report.header.subtitle` | 导出内容 | 导出内容 | Exported content | GeneratedStringSymbols_Localizable.swift:1503, RecordingExportView.swift:765 |
| `export.report.header.title` | 声音分析报告 | 声音分析报告 | Sound Analysis Report | GeneratedStringSymbols_Localizable.swift:1512, RecordingExportView.swift:762 |
| `export.report.pageNumber %lld %lld` | \(page.pageNumber) / \(page.pageCount) | %1$lld / %2$lld | %1$lld / %2$lld | GeneratedStringSymbols_Localizable.swift:1521, RecordingExportView.swift:746 |
| `export.selection.backgroundLoudnessCurve.subtitle` | 显示未检测到语音时的环境底噪，单位 dBFS | 显示未检测到语音时的环境底噪，单位 dBFS | Shows the ambient noise floor when no speech is detected, in dBFS. | GeneratedStringSymbols_Localizable.swift:1530, RecordingExportView.swift:365 |
| `export.selection.backgroundLoudnessCurve.title` | 背景响度曲线 | 背景响度曲线 | Background Loudness Curve | GeneratedStringSymbols_Localizable.swift:1539, RecordingExportView.swift:356 |
| `export.selection.charts` | 图表 | 图表 | Charts | GeneratedStringSymbols_Localizable.swift:1548, RecordingExportView.swift:66 |
| `export.selection.frequencyCurve.subtitle` | 显示可靠音高随时间的变化，单位 Hz | 显示可靠音高随时间的变化，单位 Hz | Shows reliable pitch over time, in Hz. | GeneratedStringSymbols_Localizable.swift:1557, RecordingExportView.swift:363 |
| `export.selection.frequencyCurve.title` | 频率曲线 | 频率曲线 | Frequency Curve | GeneratedStringSymbols_Localizable.swift:1566, RecordingExportView.swift:354 |
| `export.selection.loudnessCurve.subtitle` | 显示语音音量随时间的变化，单位 dBFS | 显示语音音量随时间的变化，单位 dBFS | Shows speech loudness over time, in dBFS. | GeneratedStringSymbols_Localizable.swift:1575, RecordingExportView.swift:364 |
| `export.selection.loudnessCurve.title` | 响度曲线 | 响度曲线 | Loudness Curve | GeneratedStringSymbols_Localizable.swift:1584, RecordingExportView.swift:355 |
| `export.selection.resultChart.subtitle` | 显示综合评分、标准评分和自然度 | 显示综合评分、标准评分和自然度 | Shows the overall score, standard score, and naturalness. | GeneratedStringSymbols_Localizable.swift:1593, RecordingExportView.swift:366 |
| `export.selection.resultChart.title` | 结果图 | 结果图 | Result Chart | GeneratedStringSymbols_Localizable.swift:1602, RecordingExportView.swift:357 |
| `export.sheet.defaultFilename` | Pitchee-Report.pdf | Pitchee-Report.pdf | Pitchee-Report.pdf | GeneratedStringSymbols_Localizable.swift:1611, RecordingExportView.swift:109 |
| `export.sheet.saveReport` | 保存 | 保存 | Save | GeneratedStringSymbols_Localizable.swift:1620, RecordingExportView.swift:99 |
| `export.sheet.title` | 导出 | 导出 | Export | GeneratedStringSymbols_Localizable.swift:1629, RecordingExportView.swift:95 |
| `insights.metric.baselineAverage.caption %@` | 平均基准 \(baseline) | 平均基准 %1$@ | Average baseline %1$@ | ContentView.swift:411, GeneratedStringSymbols_Localizable.swift:1647 |
| `insights.metric.compositeScore.caption` | 声音表现的整体结果 | 声音表现的整体结果 | How your voice performed overall. | ContentView.swift:153, GeneratedStringSymbols_Localizable.swift:1656 |
| `insights.metric.meanPitch.caption` | 有效语音片段的平均基频，单位 Hz | 有效语音片段的平均基频，单位 Hz | Mean fundamental frequency of voiced speech, in Hz. | ContentView.swift:173, GeneratedStringSymbols_Localizable.swift:1665 |
| `insights.metric.naturalness.caption` | 声音听起来连贯、自然的程度 | 声音听起来连贯、自然的程度 | How consistent and natural the voice sounds. | ContentView.swift:163, GeneratedStringSymbols_Localizable.swift:1674 |
| `insights.metric.speechDuration.caption` | 录音中检测到的人声时长，单位秒 | 录音中检测到的人声时长，单位秒 | Length of detected speech in the recording, in seconds. | ContentView.swift:183, GeneratedStringSymbols_Localizable.swift:1683 |
| `insights.screen.title` | 洞察 | 洞察 | Insights | ContentView.swift:103, ContentView.swift:199, GeneratedStringSymbols_Localizable.swift:1692 |
| `insights.summary.analysisCount.title` | 声音分析 | 声音分析 | Voice Analyses | ContentView.swift:269, GeneratedStringSymbols_Localizable.swift:1701 |
| `insights.summary.openedDays.title` | 打开天数 | 打开天数 | Days Opened | ContentView.swift:292, GeneratedStringSymbols_Localizable.swift:1710 |
| `onboarding.footer.finishSetup` | 完成设置 | 完成设置 | Finish Setup | GeneratedStringSymbols_Localizable.swift:1719, OnboardingView.swift:239 |
| `onboarding.footer.startSetup` | 开始设置 | 开始设置 | Get Started | GeneratedStringSymbols_Localizable.swift:1728, OnboardingView.swift:238 |
| `onboarding.footer.voiceSelectionRequired.a11y` | 请选择声音偏好 | 请选择声音偏好 | Select a voice preference to continue | GeneratedStringSymbols_Localizable.swift:1737, OnboardingView.swift:250 |
| `onboarding.pagination.pageIndicator.a11y %lld %lld` | 第 \(page.rawValue + 1) 页，共 2 页 | 第 %1$lld 页，共 %2$lld 页 | Page %1$lld of %2$lld | GeneratedStringSymbols_Localizable.swift:1746, OnboardingView.swift:127 |
| `onboarding.preferences.subtitle` | 选择一个想探索的方向，也可以暂不确定。之后随时都能调整。 | 选择一个想探索的方向，也可以暂不确定。之后随时都能调整。 | Pick a direction to explore — or stay undecided. You can change this anytime. | GeneratedStringSymbols_Localizable.swift:1755, OnboardingView.swift:201 |
| `onboarding.preferences.title` | 让我们更加了解你 | 让我们更加了解你 | Help Us Get to Know You Better | GeneratedStringSymbols_Localizable.swift:1764, OnboardingView.swift:196 |
| `onboarding.preferences.voicePrompt` | 你希望什么样的声音？ | 你希望什么样的声音？ | What kind of voice are you aiming for? | GeneratedStringSymbols_Localizable.swift:1773, OnboardingView.swift:208 |
| `onboarding.welcome.artworkBadge` | 声音分析 | 声音分析 | Voice Analysis | GeneratedStringSymbols_Localizable.swift:1782, OnboardingView.swift:182 |
| `onboarding.welcome.featurePrivacy.description` | 在设备上分析，录音不会上传。 | 在设备上分析，录音不会上传。 | Analysis runs on device; recordings are never uploaded. | GeneratedStringSymbols_Localizable.swift:1791, OnboardingView.swift:159 |
| `onboarding.welcome.featurePrivacy.title` | 你的声音由你掌控 | 你的声音由你掌控 | Your Voice Stays in Your Control | GeneratedStringSymbols_Localizable.swift:1800, OnboardingView.swift:158 |
| `onboarding.welcome.featureTrend.description` | 用数据和趋势，了解你的声音状态。 | 用数据和趋势，了解你的声音状态。 | Use data and trends to understand the state of your voice. | GeneratedStringSymbols_Localizable.swift:1809, OnboardingView.swift:154 |
| `onboarding.welcome.featureTrend.title` | 看见声音的变化 | 看见声音的变化 | See How Your Voice Changes | GeneratedStringSymbols_Localizable.swift:1818, OnboardingView.swift:153 |
| `onboarding.welcome.subtitle` | Pitchee 会把声音变成清晰、可追踪的反馈，陪你记录每一次变化。 | Pitchee 会把声音变成清晰、可追踪的反馈，陪你记录每一次变化。 | Pitchee turns your voice into clear, trackable feedback and follows every change with you. | GeneratedStringSymbols_Localizable.swift:1827, OnboardingView.swift:141 |
| `onboarding.welcome.title` | 用声音，\n更了解自己 | 用声音，\n更了解自己 | Know Yourself\nThrough Your Voice | GeneratedStringSymbols_Localizable.swift:1836, OnboardingView.swift:135 |
| `piano.note.name.a11y %@` | 音符 \(note.displayName) | 音符 %1$@ | Note %1$@ | ContentView.swift:597, GeneratedStringSymbols_Localizable.swift:1845 |
| `piano.note.playbackHint.a11y` | 轻点播放，按住可持续发声 | 轻点播放，按住可持续发声 | Tap to play. Touch and hold to sustain the sound. | ContentView.swift:598, GeneratedStringSymbols_Localizable.swift:1854 |
| `piano.screen.title` | 钢琴键 | 钢琴键 | Piano Keys | ContentView.swift:107, ContentView.swift:483, GeneratedStringSymbols_Localizable.swift:1863 |
| `recording.chart.recentWindow` | 最近 3 秒 | 最近 3 秒 | Last 3 Seconds | GeneratedStringSymbols_Localizable.swift:1872, RecordingView.swift:99 |
| `recording.controls.analyzingAudio` | 正在分析声音 | 正在分析声音 | Analyzing Audio | GeneratedStringSymbols_Localizable.swift:1881, RecordingTabAccessory.swift:96 |
| `recording.controls.preparingMicrophone` | 正在准备麦克风 | 正在准备麦克风 | Preparing Microphone | GeneratedStringSymbols_Localizable.swift:1890, RecordingTabAccessory.swift:95 |
| `recording.controls.preparingMicrophone.subtitle` | 请允许使用麦克风 | 请允许使用麦克风 | Please allow microphone access | GeneratedStringSymbols_Localizable.swift:1899, RecordingTabAccessory.swift:102 |
| `recording.controls.recordingInProgress` | 录音中 | 录音中 | Recording | GeneratedStringSymbols_Localizable.swift:1908, RecordingTabAccessory.swift:94 |
| `recording.controls.startRecording` | 开始录音 | 开始录音 | Start Recording | GeneratedStringSymbols_Localizable.swift:1917, RecordingTabAccessory.swift:90, RecordingTabAccessory.swift:97 |
| `recording.controls.startRecording.subtitle` | 自然朗读参考语料 | 自然朗读参考语料 | Read the reference passage naturally | GeneratedStringSymbols_Localizable.swift:1926, RecordingTabAccessory.swift:104 |
| `recording.controls.stopAndAnalyze` | 停止并分析 | 停止并分析 | Stop and Analyze | GeneratedStringSymbols_Localizable.swift:1935, RecordingTabAccessory.swift:88 |
| `recording.controls.stopAndAnalyze.hint` | 结束录音并打开声音报告 | 结束录音并打开声音报告 | Ends the recording and opens the voice report. | GeneratedStringSymbols_Localizable.swift:1944, RecordingTabAccessory.swift:77 |
| `recording.controls.stopAndAnalyze.subtitle` | 点击停止并分析 | 点击停止并分析 | Tap to stop and analyze | GeneratedStringSymbols_Localizable.swift:1953, RecordingTabAccessory.swift:101 |
| `recording.controls.viewAnalysisProgress` | 查看分析进度 | 查看分析进度 | View Analysis Progress | GeneratedStringSymbols_Localizable.swift:1962, RecordingTabAccessory.swift:89 |
| `recording.controls.viewAnalysisProgress.subtitle` | 点击查看进度 | 点击查看进度 | Tap to view progress | GeneratedStringSymbols_Localizable.swift:1971, RecordingTabAccessory.swift:103 |
| `recording.error.fileMissing` | 录音文件没有生成，请再试一次。 | 录音文件没有生成，请再试一次。 | The recording file wasn't created. Please try again. | AnalysisViewModel.swift:189, GeneratedStringSymbols_Localizable.swift:1980 |
| `recording.error.microphonePermissionDenied` | 请在系统设置中允许 Pitchee 使用麦克风，然后再试一次。 | 请在系统设置中允许 Pitchee 使用麦克风，然后再试一次。 | Allow Pitchee to use the microphone in Settings, then try again. | AnalysisViewModel.swift:113, GeneratedStringSymbols_Localizable.swift:1989 |
| `recording.error.microphoneUnavailable` | 无法开始录音，请检查麦克风是否可用。 | 无法开始录音，请检查麦克风是否可用。 | Can't start recording. Check that the microphone is available. | AnalysisViewModel.swift:317, GeneratedStringSymbols_Localizable.swift:1998 |
| `recording.error.realtimePitchUnavailable` | 实时音高暂时不可用，录音仍在继续，结束后将进行完整分析。 | 实时音高暂时不可用，录音仍在继续，结束后将进行完整分析。 | Live pitch is temporarily unavailable. Recording will continue and you'll get a full analysis when you stop. | AnalysisViewModel.swift:153, GeneratedStringSymbols_Localizable.swift:2007 |
| `recording.error.saveFailed` | 录音未能保存，请检查设备存储空间后重试。 | 录音未能保存，请检查设备存储空间后重试。 | The recording couldn't be saved. Check your device's storage and try again. | AnalysisViewModel.swift:184, GeneratedStringSymbols_Localizable.swift:2016 |
| `recording.error.startFailed` | 无法开始录音，请稍后再试。 | 无法开始录音，请稍后再试。 | Can't start recording. Please try again later. | AnalysisViewModel.swift:319, GeneratedStringSymbols_Localizable.swift:2025 |
| `recording.error.startFailed.title` | 无法开始录音 | 无法开始录音 | Can't Start Recording | GeneratedStringSymbols_Localizable.swift:2034, RecordingView.swift:41 |
| `recording.reference.passage` | 清晨，我推开窗户，看见阳光落在树叶上。远处传来轻轻的鸟鸣，街道也慢慢热闹起来。我想放慢脚步，用自然的声音，记录今天平凡而美好的生活。 | 清晨，我推开窗户，看见阳光落在树叶上。远处传来轻轻的鸟鸣，街道也慢慢热闹起来。我想放慢脚步，用自然的声音，记录今天平凡而美好的生活。 | Early in the morning, I pushed open the window and saw the sunlight resting on the leaves. Somewhere in the distance came the soft chirping of birds, and the street slowly grew lively. I want to slow down and, with the sounds of nature, record the ordinary yet beautiful life of today. | GeneratedStringSymbols_Localizable.swift:2043, RecordingTabAccessory.swift:109, RecordingView.swift:115 |
| `recording.reference.title` | 参考语料 | 参考语料 | Reference Passage | GeneratedStringSymbols_Localizable.swift:2052, RecordingView.swift:112 |
| `recording.screen.title` | 录制 | 录制 | Recording | ContentView.swift:105, GeneratedStringSymbols_Localizable.swift:2061, RecordingTabAccessory.swift:109, RecordingView.swift:21 |
| `recording.timeline.a11y` | 音高曲线，最近 3 秒 | 音高曲线，最近 3 秒 | Pitch curve, last 3 seconds | GeneratedStringSymbols_Localizable.swift:2070, LivePitchChartView.swift:36 |
| `recording.timeline.currentPitch.a11y %lld` | \(Int($0)) 赫兹 | %1$lld 赫兹 | %1$lld hertz | GeneratedStringSymbols_Localizable.swift:2079, LivePitchChartView.swift:24 |
| `recording.timeline.noPitchDetected.a11y` | 未检测到音高 | 未检测到音高 | No pitch detected | GeneratedStringSymbols_Localizable.swift:2088, LivePitchChartView.swift:27 |
| `recording.timeline.notRecording.a11y` | 尚未录音或录音已结束 | 尚未录音或录音已结束 | Not recording, or the recording has ended | GeneratedStringSymbols_Localizable.swift:2097, LivePitchChartView.swift:28 |
| `scoring.baseFormula.note` | Standard 是模型识别的音色标准分；Naturalness 是自然度分；F0 是平均基频，单位为 Hz。带 _r 的变量会被限制在 0 到 1 之间。Base 是应用规则前的基础分，Final 是结果页显示的综合分。 | Standard 是模型识别的音色标准分；Naturalness 是自然度分；F0 是平均基频，单位为 Hz。带 _r 的变量会被限制在 0 到 1 之间。Base 是应用规则前的基础分，Final 是结果页显示的综合分。 | Standard is the timbre standard score from the model; Naturalness is the naturalness score; F0 is the mean fundamental frequency in Hz. Variables with _r are clamped between 0 and 1. Base is the score before any rule is applied, and Final is the overall score shown on the result screen. | GeneratedStringSymbols_Localizable.swift:2115, RecordingAnalysisView.swift:634 |
| `scoring.baseFormula.subtitle` | 所有评分规则都从这些归一化步骤开始。 | 所有评分规则都从这些归一化步骤开始。 | Every scoring rule starts from these normalization steps. | GeneratedStringSymbols_Localizable.swift:2124, RecordingAnalysisView.swift:621 |
| `scoring.baseFormula.title` | 基础公式 | 基础公式 | Base Formula | GeneratedStringSymbols_Localizable.swift:2133, RecordingAnalysisView.swift:619 |
| `scoring.currentRule.badge` | 当前 | 当前 | Current | GeneratedStringSymbols_Localizable.swift:2142, RecordingAnalysisView.swift:648 |
| `scoring.currentRule.title` | 本次命中规则 | 本次命中规则 | Rule Matched This Time | GeneratedStringSymbols_Localizable.swift:2151, RecordingAnalysisView.swift:646 |
| `scoring.explanation.intro.description` | 综合评分把音色标准、自然度和平均音高放在一起计算，再根据本次命中的规则进行加分或封顶。它适合用来观察自己的练习趋势，不代表声音的整体好坏。 | 综合评分把音色标准、自然度和平均音高放在一起计算，再根据本次命中的规则进行加分或封顶。它适合用来观察自己的练习趋势，不代表声音的整体好坏。 | The overall score combines the timbre standard, naturalness, and average pitch, then applies a boost or a cap based on the rule that matched this recording. Use it to track your own practice trend — it does not judge whether a voice is good or bad. | GeneratedStringSymbols_Localizable.swift:2160, RecordingAnalysisView.swift:610 |
| `scoring.explanation.intro.title` | 综合评分如何得出 | 综合评分如何得出 | How the Overall Score Is Calculated | GeneratedStringSymbols_Localizable.swift:2169, RecordingAnalysisView.swift:608 |
| `scoring.explanation.title` | 评分说明 | 评分说明 | Score Explanation | GeneratedStringSymbols_Localizable.swift:2178, RecordingAnalysisView.swift:602 |
| `scoring.otherRules.title` | 其他评分规则 | 其他评分规则 | Other Scoring Rules | GeneratedStringSymbols_Localizable.swift:2187, RecordingAnalysisView.swift:703 |
| `scoring.ruleDetail.condition` | 触发条件 | 触发条件 | Trigger Condition | GeneratedStringSymbols_Localizable.swift:2196, RecordingAnalysisView.swift:658 |
| `scoring.ruleDetail.formula` | 计算公式 | 计算公式 | Formula | GeneratedStringSymbols_Localizable.swift:2205, RecordingAnalysisView.swift:659 |
| `scoring.ruleDetail.result` | 处理结果 | 处理结果 | Result | GeneratedStringSymbols_Localizable.swift:2214, RecordingAnalysisView.swift:661 |
| `scoring.rules.continuous.condition` | 未命中其他封顶或提升规则 | 未命中其他封顶或提升规则 | No other cap or boost rule matched | GeneratedStringSymbols_Localizable.swift:2223, RecordingAnalysisView.swift:758 |
| `scoring.rules.continuous.description` | 这次没有触发特殊限制，综合分直接使用 Base。 | 这次没有触发特殊限制，综合分直接使用 Base。 | No special limit was triggered this time, so the overall score uses Base directly. | GeneratedStringSymbols_Localizable.swift:2232, RecordingAnalysisView.swift:757 |
| `scoring.rules.continuous.result` | 综合分采用 Base。 | 综合分采用 Base。 | The overall score uses Base. | GeneratedStringSymbols_Localizable.swift:2241, RecordingAnalysisView.swift:760 |
| `scoring.rules.continuous.title` | 连续评分 | 连续评分 | Continuous Scoring | GeneratedStringSymbols_Localizable.swift:2250, RecordingAnalysisView.swift:756 |
| `scoring.rules.f0Unavailable.condition` | 没有可靠的 F0 | 没有可靠的 F0 | No reliable F0 | GeneratedStringSymbols_Localizable.swift:2259, RecordingAnalysisView.swift:813 |
| `scoring.rules.f0Unavailable.description` | 没有识别到稳定基频，下次可以在安静环境中离麦克风近一点。 | 没有识别到稳定基频，下次可以在安静环境中离麦克风近一点。 | No stable fundamental frequency was detected — next time try a quieter place and hold the phone closer to your mouth. | GeneratedStringSymbols_Localizable.swift:2268, RecordingAnalysisView.swift:812 |
| `scoring.rules.f0Unavailable.result` | 综合分直接采用标准音色分 Standard。 | 综合分直接采用标准音色分 Standard。 | The overall score uses the timbre standard score (Standard) directly. | GeneratedStringSymbols_Localizable.swift:2277, RecordingAnalysisView.swift:815 |
| `scoring.rules.f0Unavailable.title` | 基频不可用 | 基频不可用 | Pitch Unavailable | GeneratedStringSymbols_Localizable.swift:2286, RecordingAnalysisView.swift:811 |
| `scoring.rules.highF0MaleCap.condition` | F0 > 165，Naturalness ≥ 50，Standard < 50 | F0 > 165，Naturalness ≥ 50，Standard < 50 | F0 > 165, Naturalness ≥ 50, Standard < 50 | GeneratedStringSymbols_Localizable.swift:2295, RecordingAnalysisView.swift:805 |
| `scoring.rules.highF0MaleCap.description` | 音高和自然度已经达标，接下来重点练习音色，让声音更明亮、更轻松。 | 音高和自然度已经达标，接下来重点练习音色，让声音更明亮、更轻松。 | Pitch and naturalness are already on target; now focus on timbre to make your voice brighter and more relaxed. | GeneratedStringSymbols_Localizable.swift:2304, RecordingAnalysisView.swift:804 |
| `scoring.rules.highF0MaleCap.result` | 综合分最高为 59。 | 综合分最高为 59。 | The overall score is capped at 59. | GeneratedStringSymbols_Localizable.swift:2313, RecordingAnalysisView.swift:807 |
| `scoring.rules.highF0MaleCap.title` | 音色分不足 | 音色分不足 | Timbre Score Too Low | GeneratedStringSymbols_Localizable.swift:2322, RecordingAnalysisView.swift:803 |
| `scoring.rules.highF0StylizedCap.condition` | F0 > 165，Naturalness < 50 | F0 > 165，Naturalness < 50 | F0 > 165, Naturalness < 50 | GeneratedStringSymbols_Localizable.swift:2331, RecordingAnalysisView.swift:781 |
| `scoring.rules.highF0StylizedCap.description` | 音高已经上去了，但自然度还没跟上。下一次先放松语气，不必刻意抬高音调。 | 音高已经上去了，但自然度还没跟上。下一次先放松语气，不必刻意抬高音调。 | Your pitch is already up, but naturalness hasn't caught up. Next time relax your tone first — there's no need to push your pitch higher. | GeneratedStringSymbols_Localizable.swift:2340, RecordingAnalysisView.swift:780 |
| `scoring.rules.highF0StylizedCap.result` | 综合分最高为 30。 | 综合分最高为 30。 | The overall score is capped at 30. | GeneratedStringSymbols_Localizable.swift:2349, RecordingAnalysisView.swift:783 |
| `scoring.rules.highF0StylizedCap.title` | 高基频、低自然度封顶 | 高基频、低自然度封顶 | High Pitch with Low Naturalness Cap | GeneratedStringSymbols_Localizable.swift:2358, RecordingAnalysisView.swift:779 |
| `scoring.rules.lowF0NaturalCap.condition` | F0 ≤ 165，Naturalness ≥ 50 | F0 ≤ 165，Naturalness ≥ 50 | F0 ≤ 165, Naturalness ≥ 50 | GeneratedStringSymbols_Localizable.swift:2367, RecordingAnalysisView.swift:789 |
| `scoring.rules.lowF0NaturalCap.description` | 自然度已经不错，接下来可以把注意力放在音高上。 | 自然度已经不错，接下来可以把注意力放在音高上。 | Naturalness is already good — now you can focus on pitch. | GeneratedStringSymbols_Localizable.swift:2376, RecordingAnalysisView.swift:788 |
| `scoring.rules.lowF0NaturalCap.result` | 综合分最高为 59。 | 综合分最高为 59。 | The overall score is capped at 59. | GeneratedStringSymbols_Localizable.swift:2385, RecordingAnalysisView.swift:791 |
| `scoring.rules.lowF0NaturalCap.title` | 低基频封顶 | 低基频封顶 | Low Pitch Cap | GeneratedStringSymbols_Localizable.swift:2394, RecordingAnalysisView.swift:787 |
| `scoring.rules.lowF0StylizedCap.condition` | F0 ≤ 165，Naturalness < 50 | F0 ≤ 165，Naturalness < 50 | F0 ≤ 165, Naturalness < 50 | GeneratedStringSymbols_Localizable.swift:2403, RecordingAnalysisView.swift:797 |
| `scoring.rules.lowF0StylizedCap.description` | 这次音高和自然度都需要照顾。先放慢一点，完整自然地说完句子。 | 这次音高和自然度都需要照顾。先放慢一点，完整自然地说完句子。 | This time both pitch and naturalness need attention. Slow down a little and finish your sentences naturally. | GeneratedStringSymbols_Localizable.swift:2412, RecordingAnalysisView.swift:796 |
| `scoring.rules.lowF0StylizedCap.result` | 综合分最高为 20。 | 综合分最高为 20。 | The overall score is capped at 20. | GeneratedStringSymbols_Localizable.swift:2421, RecordingAnalysisView.swift:799 |
| `scoring.rules.lowF0StylizedCap.title` | 低基频、低自然度 | 低基频、低自然度 | Low Pitch and Low Naturalness | GeneratedStringSymbols_Localizable.swift:2430, RecordingAnalysisView.swift:795 |
| `scoring.rules.passBoost.condition` | F0 > 165，Naturalness > 80，Standard > 50 | F0 > 165，Naturalness > 80，Standard > 50 | F0 > 165, Naturalness > 80, Standard > 50 | GeneratedStringSymbols_Localizable.swift:2439, RecordingAnalysisView.swift:766 |
| `scoring.rules.passBoost.description` | 三项指标都已经过线，系统会把稳定、自然的表现向上提升。 | 三项指标都已经过线，系统会把稳定、自然的表现向上提升。 | All three metrics passed their thresholds, so the system pushes a steady, natural performance upward. | GeneratedStringSymbols_Localizable.swift:2448, RecordingAnalysisView.swift:765 |
| `scoring.rules.passBoost.result` | 综合分最高为 100；如果 promoted 高于 Base，就采用 promoted。 | 综合分最高为 100；如果 promoted 高于 Base，就采用 promoted。 | The overall score is capped at 100; if promoted is higher than Base, promoted is used. | GeneratedStringSymbols_Localizable.swift:2457, RecordingAnalysisView.swift:775 |
| `scoring.rules.passBoost.title` | 加分 | 加分 | Score Boost | GeneratedStringSymbols_Localizable.swift:2466, RecordingAnalysisView.swift:764 |
| `settings.screen.title` | 偏好与隐私 | 偏好与隐私 | Preferences & Privacy | ContentView.swift:232, GeneratedStringSymbols_Localizable.swift:2475, SettingsView.swift:48 |
| `settings.voicePreference.autosaveNote` | 选择会自动保存，用于记录你的练习方向。当前偏好不会改变分析评分。 | 选择会自动保存，用于记录你的练习方向。当前偏好不会改变分析评分。 | Your choice is saved automatically and records the direction you are practicing. It does not change your analysis scores. | GeneratedStringSymbols_Localizable.swift:2484, SettingsView.swift:35 |
| `settings.voicePreference.headline.subtitle` | 可以有明确的目标，也可以先探索。你随时都能回来调整。 | 可以有明确的目标，也可以先探索。你随时都能回来调整。 | Set a clear goal or just explore — you can come back and adjust anytime. | GeneratedStringSymbols_Localizable.swift:2493, SettingsView.swift:23 |
| `settings.voicePreference.headline.title` | 找到你的声音方向 | 找到你的声音方向 | Find Your Voice Direction | GeneratedStringSymbols_Localizable.swift:2502, SettingsView.swift:21 |
| `settings.voicePreference.sectionTitle` | 声音偏好 | 声音偏好 | Voice Preference | GeneratedStringSymbols_Localizable.swift:2511, SettingsView.swift:29 |
| `voiceProfile.option.feminine.description` | 探索更明亮、柔和的声音 | 探索更明亮、柔和的声音 | Explore a brighter, softer sound | GeneratedStringSymbols_Localizable.swift:2520, VoicePreferences.swift:30 |
| `voiceProfile.option.feminine.title` | 女性向声音 | 女性向声音 | Feminine-Leaning Voice | GeneratedStringSymbols_Localizable.swift:2529, VoicePreferences.swift:22 |
| `voiceProfile.option.masculine.description` | 探索更低沉、厚实的声音 | 探索更低沉、厚实的声音 | Explore a lower, fuller sound | GeneratedStringSymbols_Localizable.swift:2538, VoicePreferences.swift:29 |
| `voiceProfile.option.masculine.title` | 男性向声音 | 男性向声音 | Masculine-Leaning Voice | GeneratedStringSymbols_Localizable.swift:2547, VoicePreferences.swift:21 |
| `voiceProfile.option.undecided.description` | 先了解自己的声音，慢慢找到方向 | 先了解自己的声音，慢慢找到方向 | Start by getting to know your voice and find your direction over time | GeneratedStringSymbols_Localizable.swift:2556, VoicePreferences.swift:31 |
| `voiceProfile.option.undecided.title` | 暂不确定 | 暂不确定 | Not Sure Yet | GeneratedStringSymbols_Localizable.swift:2565, VoicePreferences.swift:23 |
| `voiceProfile.privacyPromise.onDevice.description` | 声音分析在本机完成，录音不会上传到服务器，也不会共享给第三方。 | 声音分析在本机完成，录音不会上传到服务器，也不会共享给第三方。 | Voice analysis happens on this device. Recordings are never uploaded to a server or shared with third parties. | GeneratedStringSymbols_Localizable.swift:2574, VoicePreferences.swift:95 |
| `voiceProfile.privacyPromise.onDevice.title` | 只在设备上分析 | 只在设备上分析 | Analyzed Only on Your Device | GeneratedStringSymbols_Localizable.swift:2583, VoicePreferences.swift:95 |
| `voiceProfile.privacyPromise.recordingUsage.description` | 分析结束后清理临时录音，历史记录仅保存分析结果。 | 分析结束后清理临时录音，历史记录仅保存分析结果。 | Temporary recordings are deleted after analysis; history keeps only the analysis results. | GeneratedStringSymbols_Localizable.swift:2592, VoicePreferences.swift:96 |
| `voiceProfile.privacyPromise.recordingUsage.title` | 录音仅用于本次分析 | 录音仅用于本次分析 | Recordings Are Used Only for This Analysis | GeneratedStringSymbols_Localizable.swift:2601, VoicePreferences.swift:96 |
| `voiceProfile.privacyPromise.title` | 隐私保护承诺 | 隐私保护承诺 | Our Privacy Promise | GeneratedStringSymbols_Localizable.swift:2610, VoicePreferences.swift:93 |
| `voiceProfile.privacyPromise.userControl.description` | 声音偏好可随时修改。麦克风权限可在系统设置中关闭。 | 声音偏好可随时修改。麦克风权限可在系统设置中关闭。 | You can change your voice preference at any time, and turn off microphone access in system settings. | GeneratedStringSymbols_Localizable.swift:2619, VoicePreferences.swift:97 |
| `voiceProfile.privacyPromise.userControl.title` | 选择始终由你掌控 | 选择始终由你掌控 | You Stay in Control of Your Choices | GeneratedStringSymbols_Localizable.swift:2628, VoicePreferences.swift:97 |
