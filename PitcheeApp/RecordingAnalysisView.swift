//
//  RecordingAnalysisView.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/18.
//

import SwiftUI
import LaTeXSwiftUI

struct RecordingAnalysisView: View {
    @ObservedObject var viewModel: AnalysisViewModel

    var body: some View {
        Group {
            if viewModel.isAnalyzing {
                stateScroll { analyzingState }
            } else if let result = viewModel.result {
                RecordingResultView(
                    result: result,
                    volumeStatistics: viewModel.volumeStatistics,
                    saveError: viewModel.errorMessage
                )
            } else {
                stateScroll {
                    ContentUnavailableView {
                        Label("这次没有完成分析", systemImage: "waveform.badge.exclamationmark")
                    } description: {
                        Text(viewModel.errorMessage ?? "请返回录制，再录一段自然说话。")
                    }
                    .padding(.top, 60)
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(viewModel.isAnalyzing ? "正在分析" : "结果")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isAnalyzing)
        .toolbar {
            if let result = viewModel.result, !viewModel.isAnalyzing {
                ToolbarItem(placement: .topBarTrailing) {
                    PitchImageExportButton { PitchTimeline(result: result) }
                        .labelStyle(.iconOnly)
                }
            }
        }
        .onDisappear {
            if !viewModel.hasResult && !viewModel.isAnalyzing { viewModel.clearError() }
        }
    }

    private func stateScroll<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            content()
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .padding(24)
        }
    }

    private var analyzingState: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform.path")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.accentColor)
                .frame(width: 112, height: 112)
                .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 32))
            VStack(spacing: 10) {
                Text("正在听懂你的声音")
                    .font(.title2.weight(.bold))
                Text("正在设备上分析音高与声音特征。\n首次分析可能需要一点时间。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ProgressView().controlSize(.large)
            Label("声音留在你的设备上", systemImage: "lock.shield")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 70)
    }
}

struct RecordingResultView: View {
    let result: PitcheeAnalysisResult
    let volumeStatistics: RecordingVolumeStatistics?
    let saveError: String?

    @State private var showsVoiceDetails = false
    @State private var selectedSuggestion: ResultSuggestion?
    @State private var selectedResource: ResultResource?

    var body: some View {
        FoldAwareArrangementView(
            primary: { resultPane(resultOverview) },
            secondary: { resultPane(resultSecondary) },
            regular: { resultScroll(allContent) }
        )
        .background(Color(uiColor: .systemGroupedBackground))
        .sheet(isPresented: $showsVoiceDetails) {
            voiceDetailsSheet
        }
        .sheet(item: $selectedSuggestion) { suggestion in
            ResultSuggestionSheet(suggestion: suggestion)
        }
        .sheet(item: $selectedResource) { resource in
            ResultResourceSheet(resource: resource)
        }
    }

    private var resultOverview: some View {
        VStack(alignment: .leading, spacing: 24) {
            scoreSummary

            Button {
                showsVoiceDetails = true
            } label: {
                HStack(spacing: 12) {
                    Label("声音详情", systemImage: "waveform.path.ecg")
                        .font(.subheadline.weight(.semibold))
                    Spacer(minLength: 12)
                    Text("音高与音量")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            VoiceProfileReferenceChart(
                femalePercentage: result.vfp.vfpStandardScore,
                meanPitchHz: result.f0.meanHz,
                pitchRangeHz: pitchRangeHz
            )

            if let saveError {
                Label(saveError, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var resultSecondary: some View {
        VStack(alignment: .leading, spacing: 28) {
            suggestionsSection
            resourcesSection
        }
    }

    private var allContent: some View {
        VStack(alignment: .leading, spacing: 28) {
            resultOverview
            Divider()
            resultSecondary
        }
    }

    private func resultScroll<Content: View>(_ content: Content) -> some View {
        ScrollView {
            content
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .padding(24)
        }
    }

    private func resultPane<Content: View>(_ content: Content) -> some View {
        resultScroll(content)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("建议")
                    .font(.title2.weight(.bold))
                Text("根据这次录音，下一步可以这样练习")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                ForEach(suggestions) { suggestion in
                    Button {
                        selectedSuggestion = suggestion
                    } label: {
                        suggestionRow(suggestion)
                    }
                    .buttonStyle(.plain)

                    if suggestion.id != suggestions.last?.id {
                        Divider()
                            .padding(.leading, 54)
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func suggestionRow(_ suggestion: ResultSuggestion) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: suggestion.symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(suggestion.tint)
                .frame(width: 30, height: 30)
                .background(suggestion.tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(suggestion.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
        }
        .padding(.vertical, 15)
        .contentShape(Rectangle())
    }

    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("练习资源")
                    .font(.title2.weight(.bold))
                Text("把建议带到下一次练习里")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(resources) { resource in
                    Button {
                        selectedResource = resource
                    } label: {
                        resourceRow(resource)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func resourceRow(_ resource: ResultResource) -> some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(resource.tint.gradient)
                    .frame(width: 92, height: 66)
                Image(systemName: resource.symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Text(resource.badge)
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                    .padding(6)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(resource.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(resource.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
    }

    private var suggestions: [ResultSuggestion] {
        let needsLongerRecording = result.vad.speechSeconds < 5
        let naturalnessNeedsWork = result.naturalness.score < 70

        return [
            ResultSuggestion(
                id: "duration",
                title: needsLongerRecording ? "下次多录一会儿" : "保持相近的录音时长",
                detail: needsLongerRecording
                    ? "有效语音不足 5 秒，更多声音信息会让结果更稳定。"
                    : "继续用相近时长录制，方便比较每次变化。",
                symbol: "timer",
                tint: .blue,
                expandedDetail: needsLongerRecording
                    ? "试着连续说 10 秒以上的自然句子。录音更完整，音高和自然度的估计会更稳定。"
                    : "你已经提供了足够的语音信息。下次保持相近时长，趋势会更容易看懂。"
            ),
            ResultSuggestion(
                id: "naturalness",
                title: naturalnessNeedsWork ? "让语气更自然" : "继续保持自然语气",
                detail: naturalnessNeedsWork
                    ? "放慢语速，保持连续呼吸，再试着说一段熟悉的话。"
                    : "这次自然度表现不错，保持放松和连贯的表达。",
                symbol: "waveform",
                tint: .orange,
                expandedDetail: naturalnessNeedsWork
                    ? "先放松下颌和肩膀，用熟悉的句子练习。不要刻意压低或抬高音高，先让表达保持连贯。"
                    : "自然度是一个参考值。保持轻松的语速和连贯的呼吸，比追求单次分数更有帮助。"
            )
        ]
    }

    private var resources: [ResultResource] {
        [
            ResultResource(
                id: "naturalness-video",
                title: "自然度训练",
                detail: "视频练习 · 放松与连贯表达",
                badge: "01:09",
                symbol: "play.fill",
                tint: .blue,
                body: "用一段短练习找到更放松的语气，再回到录音页试一次。"
            ),
            ResultResource(
                id: "voice-research",
                title: "声音研究",
                detail: "文章 · 了解音高与自然度",
                badge: "阅读",
                symbol: "doc.text.image",
                tint: .purple,
                body: "了解音高、自然度与录音条件之间的关系，把结果当成长期练习的参考。"
            )
        ]
    }

    private var voiceDetailsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("声音指标")
                            .font(.title3.weight(.bold))
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                            ResultMetric(title: "自然度", value: scoreText(result.naturalness.score), unit: "/ 100", symbol: "leaf")
                            ResultMetric(title: "标准评分", value: scoreText(result.vfp.vfpStandardScore), unit: "/ 100", symbol: "slider.horizontal.3")
                            ResultMetric(title: "有效语音", value: result.vad.speechSeconds.formatted(.number.precision(.fractionLength(1))), unit: "秒", symbol: "bubble.left")
                        }
                    }

                    recordingStatistics
                    explanationSection
                }
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .padding(24)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("声音详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { showsVoiceDetails = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("读懂这次声音").font(.title3.weight(.bold))
            explanation("音高是声音的轮廓", symbol: "waveform.path", detail: result.f0.meanHz == nil
                ? "这次没有得到可靠的平均音高。试着在安静环境中，连续说一段自然的话。"
                : "平均音高反映声音的高低，不代表好坏。观察多次录音的变化，比追求某一个数值更有意义。")
            Divider()
            explanation("自然度是一个参考", symbol: "leaf", detail: "这是模型对声音自然程度的估计。建议在相似的环境下录制，再比较自己的变化。")
            Divider()
            explanation(result.vad.speechSeconds < 5 ? "下次，多说一会儿" : "试着记录同一段话", symbol: "arrow.trianglehead.repeat", detail: result.vad.speechSeconds < 5
                ? "本次有效语音不足 5 秒。下次可以放慢节奏、多说几句，让分析获得更多声音信息。"
                : "下次用相近的语速和音量说同一段话，会更容易比较两次声音的差异。")
        }
        .padding(22)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
    }

    private var scoreSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("综合评分")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                NavigationLink {
                    ScoreExplanationView(result: result)
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("查看评分如何得出")
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(scoreText(result.composite.finalScore))
                    .font(.system(size: 78, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.accentColor)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                Text("/ 100")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }

            ProgressView(value: scoreProgress, total: 1)
                .tint(Color.accentColor)
                .scaleEffect(x: 1, y: 1.35, anchor: .center)
                .accessibilityLabel("综合评分进度")
                .accessibilityValue("\(scoreText(result.composite.finalScore)) 分，共 100 分")

            Text(scoreHeadline)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("综合评分 \(scoreText(result.composite.finalScore)) 分，满分 100 分")
    }

    private var scoreProgress: Double {
        min(max(result.composite.finalScore / 100, 0), 1)
    }

    private var scoreHeadline: String {
        switch result.composite.finalScore {
        case 90...: return "这次表现很亮眼，继续保持稳定的表达。"
        case 70..<90: return "基础表现不错，针对下面的建议再练一次。"
        default: return "把下面的一条建议带到下一次录音里，结果会更有参考价值。"
        }
    }

    private var recordingStatistics: some View {
        VStack(alignment: .leading, spacing: 24) {
            compactStatisticsSection(title: "Pitch", metrics: pitchMetrics)

            compactStatisticsSection(title: "Volume", metrics: volumeMetrics)

            Text("音量使用 dBFS 表示，0 dBFS 为设备可记录的最大值；平均值和中位数下方显示高于环境底噪的音量。")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var pitchRangeHz: ClosedRange<Double>? {
        let statistics = RecordingPitchStatistics(pitch: result.f0)
        guard let low = statistics.low5Hz,
              let high = statistics.high95Hz else { return nil }
        return low...high
    }

    private var pitchMetrics: [CompactMetric] {
        let statistics = RecordingPitchStatistics(pitch: result.f0)
        let dominantBand = dominantPitchBand(statistics)
        return [
            CompactMetric(title: "平均音高", value: metricNumber(statistics.averageHz), unit: "Hz", symbol: "waveform.path"),
            CompactMetric(title: "中位音高", value: metricNumber(statistics.medianHz), unit: "Hz", symbol: "equal"),
            CompactMetric(title: "核心音域", value: pitchRangeText(statistics), unit: "Hz · 5–95%", symbol: "arrow.left.and.right"),
            CompactMetric(title: "主要音域", value: dominantBand.name, unit: dominantBand.percentage, symbol: "scope")
        ]
    }

    private var volumeMetrics: [CompactMetric] {
        [
            CompactMetric(title: "环境底噪", value: metricNumber(volumeStatistics?.environmentDBFS), unit: "dBFS", symbol: "wind"),
            CompactMetric(title: "平均音量", value: metricNumber(volumeStatistics?.averageDBFS), unit: volumeUnit(volumeStatistics?.averageDBFS), symbol: "speaker.wave.2"),
            CompactMetric(title: "中位音量", value: metricNumber(volumeStatistics?.medianDBFS), unit: volumeUnit(volumeStatistics?.medianDBFS), symbol: "equal"),
            CompactMetric(title: "音量范围", value: volumeRangeText, unit: "dBFS · 5–95%", symbol: "arrow.left.and.right")
        ]
    }

    private func compactStatisticsSection(
        title: LocalizedStringKey,
        metrics: [CompactMetric]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.bold))
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 140), spacing: 12)],
                spacing: 12
            ) {
                ForEach(metrics.indices, id: \.self) { index in
                    let metric = metrics[index]
                    ResultMetric(
                        title: metric.title,
                        value: metric.value,
                        unit: metric.unit,
                        symbol: metric.symbol
                    )
                }
            }
        }
    }

    private func metricNumber(_ value: Double?) -> String {
        guard let value else { return "—" }
        return value.formatted(.number.precision(.fractionLength(1)))
    }

    private func pitchRangeText(_ statistics: RecordingPitchStatistics) -> String {
        guard let low = statistics.low5Hz,
              let high = statistics.high95Hz else { return "—" }
        return "\(metricNumber(low))–\(metricNumber(high))"
    }

    private func dominantPitchBand(
        _ statistics: RecordingPitchStatistics
    ) -> (name: String, percentage: String) {
        guard statistics.medianHz != nil else { return ("—", "") }
        let bands = [
            ("很高", statistics.veryHighPercentage),
            ("女性", statistics.femininePercentage),
            ("中性", statistics.androgynousPercentage),
            ("男性", statistics.masculinePercentage),
            ("很低", statistics.veryLowPercentage)
        ]
        guard let dominant = bands.max(by: { $0.1 < $1.1 }) else { return ("—", "") }
        return (
            dominant.0,
            dominant.1.formatted(.percent.precision(.fractionLength(0)))
        )
    }

    private func volumeUnit(_ value: Double?) -> String {
        guard let value,
              let environment = volumeStatistics?.environmentDBFS else { return "dBFS" }
        let delta = (value - environment).formatted(
            .number
                .sign(strategy: .always())
                .precision(.fractionLength(1))
        )
        return "dBFS · \(delta) dB"
    }

    private var volumeRangeText: String {
        guard let low = volumeStatistics?.low5DBFS,
              let high = volumeStatistics?.high95DBFS else { return "—" }
        return "\(metricNumber(low))–\(metricNumber(high))"
    }

    private func scoreText(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }

    private func explanation(_ title: LocalizedStringKey, symbol: String, detail: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 7) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

private struct ScoreExplanationView: View {
    let result: PitcheeAnalysisResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                intro
                currentMetrics
                commonFormulaSection
                currentRuleSection
                otherRulesSection
            }
            .frame(maxWidth: 600, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("评分说明")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("综合评分如何得出")
                .font(.title2.weight(.bold))
            Text("综合评分把音色标准、自然度和平均音高放在一起计算，再根据本次命中的规则进行加分或封顶。它适合用来观察自己的练习趋势，不代表声音的整体好坏。")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var currentMetrics: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("本次指标")
                .font(.title3.weight(.bold))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 138), spacing: 12)], spacing: 12) {
                explanationMetric("标准音色", value: scoreText(result.vfp.vfpStandardScore), unit: "/ 100", symbol: "slider.horizontal.3")
                explanationMetric("自然度", value: scoreText(result.naturalness.score), unit: "/ 100", symbol: "leaf")
                explanationMetric(
                    "平均 F0",
                    value: f0Text,
                    unit: result.f0.meanHz == nil ? "" : "Hz",
                    symbol: "waveform.path"
                )
                explanationMetric("Base", value: scoreText(result.composite.baseScore), unit: "/ 100", symbol: "function")
                explanationMetric("Final", value: scoreText(result.composite.finalScore), unit: "/ 100", symbol: "checkmark.seal")
            }
        }
    }

    private func explanationMetric(_ title: String, value: String, unit: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var commonFormulaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("基础公式")
                .font(.title3.weight(.bold))
            Text("所有评分规则都从这些归一化步骤开始。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            FormulaBlock(lines: [
                #"\mathrm{Standard} = \mathrm{vfp\_standard\_score}"#,
                #"\mathrm{Naturalness} = \mathrm{naturalness\_score}"#,
                #"F_0 = \mathrm{mean\_f0\_hz}"#,
                #"\mathrm{Standard}_r = \frac{\mathrm{Standard}}{100}"#,
                #"\mathrm{Naturalness}_r = \min\left(1, \max\left(0, \frac{\mathrm{Naturalness} - 40}{50}\right)\right)"#,
                #"F_{0r} = \min\left(1, \max\left(0, \frac{F_0 - 110}{90}\right)\right)"#,
                #"\begin{aligned}\mathrm{Base} &= 100 \times \bigl(0.50\,\mathrm{Standard}_r + 0.20\,\mathrm{Naturalness}_r \\ &\quad + 0.15\,F_{0r} + 0.15\,\mathrm{Standard}_r\,\mathrm{Naturalness}_r\,F_{0r}\bigr)\end{aligned}"#,
                #"\mathrm{Final} = \mathrm{rule}(\mathrm{Base}, \mathrm{Standard}, \mathrm{Naturalness}, F_0)"#
            ])
            Text("Standard 是模型识别的音色标准分；Naturalness 是自然度分；F0 是平均基频，单位为 Hz。带 _r 的变量会被限制在 0 到 1 之间。Base 是应用规则前的基础分，Final 是结果页显示的综合分。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var currentRuleSection: some View {
        let rule = currentRuleDocumentation

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("本次命中规则")
                    .font(.title3.weight(.bold))
                Text("当前")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
            }
            Text(rule.guidance)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            ruleDetail("触发条件", text: rule.condition)
            ruleDetail("计算公式", text: nil)
            FormulaBlock(lines: rule.formulas)
            ruleDetail("处理结果", text: rule.result)
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func ruleDetail(_ title: String, text: String?) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if let text {
                Text(text)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var otherRulesSection: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(scoreRuleDocumentation.filter { $0.id != result.composite.rule }) { rule in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(rule.title)
                            .font(.subheadline.weight(.semibold))
                        Text(rule.condition)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(rule.result)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)

                    if rule.id != scoreRuleDocumentation.filter({ $0.id != result.composite.rule }).last?.id {
                        Divider()
                    }
                }
            }
            .padding(.top, 6)
        } label: {
            Label("其他评分规则", systemImage: "list.bullet.rectangle")
                .font(.subheadline.weight(.semibold))
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var currentRuleDocumentation: ScoreRuleDocumentation {
        scoreRuleDocumentation.first { $0.id == result.composite.rule } ?? scoreRuleDocumentation[0]
    }

    private var f0Text: String {
        guard let f0 = result.f0.meanHz, f0.isFinite, f0 > 0 else { return "—" }
        return f0.formatted(.number.precision(.fractionLength(0)))
    }

    private func scoreText(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }
}

private struct FormulaBlock: View {
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                LaTeX("\\[\(line)\\]")
                    .font(.subheadline)
                    .imageRenderingMode(.template)
                    .blockMode(.blockViews)
                    .errorMode(.rendered)
                    .renderingStyle(.redactedOriginal)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(alignment: .leading) {
            Capsule()
                .fill(Color.accentColor)
                .frame(width: 3)
                .padding(.vertical, 10)
        }
    }
}

private struct ScoreRuleDocumentation: Identifiable {
    let id: String
    let title: String
    let guidance: String
    let condition: String
    let formulas: [String]
    let result: String
}

private let scoreRuleDocumentation: [ScoreRuleDocumentation] = [
    ScoreRuleDocumentation(
        id: "continuous",
        title: "连续评分",
        guidance: "这次没有触发特殊限制，综合分直接使用 Base。",
        condition: "未命中其他封顶或提升规则",
        formulas: [#"\mathrm{Final} = \mathrm{Base}"#],
        result: "综合分采用 Base。"
    ),
    ScoreRuleDocumentation(
        id: "pass_boost",
        title: "加分",
        guidance: "三项指标都已经过线，系统会把稳定、自然的表现向上提升。",
        condition: "F0 > 165，Naturalness > 80，Standard > 50",
        formulas: [
            #"s_{F0} = \frac{F_0 - 165}{25}"#,
            #"s_N = \frac{\mathrm{Naturalness} - 80}{20}"#,
            #"s_S = \frac{\mathrm{Standard} - 50}{30}"#,
            #"\mathrm{strength} = \min(s_{F0}, s_N, s_S, 1)"#,
            #"\mathrm{promoted} = 60 + 40\,\mathrm{strength}"#,
            #"\mathrm{Final} = \max(\mathrm{Base}, \mathrm{promoted})"#
        ],
        result: "综合分最高为 100；如果 promoted 高于 Base，就采用 promoted。"
    ),
    ScoreRuleDocumentation(
        id: "high_f0_stylized_cap",
        title: "高基频、低自然度封顶",
        guidance: "音高已经上去了，但自然度还没跟上。下一次先放松语气，不必刻意抬高音调。",
        condition: "F0 > 165，Naturalness < 50",
        formulas: [#"\mathrm{Final} = \min(\mathrm{Base}, 30)"#],
        result: "综合分最高为 30。"
    ),
    ScoreRuleDocumentation(
        id: "low_f0_natural_cap",
        title: "低基频封顶",
        guidance: "自然度已经不错，接下来可以把注意力放在音高上。",
        condition: "F0 ≤ 165，Naturalness ≥ 50",
        formulas: [#"\mathrm{Final} = \min(\mathrm{Base}, 59)"#],
        result: "综合分最高为 59。"
    ),
    ScoreRuleDocumentation(
        id: "low_f0_stylized_cap",
        title: "低基频、低自然度",
        guidance: "这次音高和自然度都需要照顾。先放慢一点，完整自然地说完句子。",
        condition: "F0 ≤ 165，Naturalness < 50",
        formulas: [#"\mathrm{Final} = \min(\mathrm{Base}, 20)"#],
        result: "综合分最高为 20。"
    ),
    ScoreRuleDocumentation(
        id: "high_f0_male_cap",
        title: "音色分不足",
        guidance: "音高和自然度已经达标，接下来重点练习音色，让声音更明亮、更轻松。",
        condition: "F0 > 165，Naturalness ≥ 50，Standard < 50",
        formulas: [#"\mathrm{Final} = \min(\mathrm{Base}, 59)"#],
        result: "综合分最高为 59。"
    ),
    ScoreRuleDocumentation(
        id: "f0_unavailable",
        title: "基频不可用",
        guidance: "没有识别到稳定基频，下次可以在安静环境中离麦克风近一点。",
        condition: "没有可靠的 F0",
        formulas: [#"\mathrm{Final} = \mathrm{Standard}"#],
        result: "综合分直接采用标准音色分 Standard。"
    )
]

private struct ResultSuggestion: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let tint: Color
    let expandedDetail: String
}

private struct ResultResource: Identifiable {
    let id: String
    let title: String
    let detail: String
    let badge: String
    let symbol: String
    let tint: Color
    let body: String
}

private struct ResultSuggestionSheet: View {
    let suggestion: ResultSuggestion
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: suggestion.symbol)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(suggestion.tint)
                    .frame(width: 64, height: 64)
                    .background(suggestion.tint.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 8) {
                    Text(suggestion.title)
                        .font(.title2.weight(.bold))
                    Text(suggestion.expandedDetail)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .frame(maxWidth: 560, alignment: .leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("练习建议")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct ResultResourceSheet: View {
    let resource: ResultResource
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(resource.tint.gradient)
                    Image(systemName: resource.symbol)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(height: 160)

                VStack(alignment: .leading, spacing: 8) {
                    Text(resource.title)
                        .font(.title2.weight(.bold))
                    Text(resource.body)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .frame(maxWidth: 560, alignment: .leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(resource.badge == "阅读" ? "文章" : "视频")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct VoiceProfileReferenceChart: View {
    let femalePercentage: Double
    let meanPitchHz: Double?
    let pitchRangeHz: ClosedRange<Double>?

    private let minimumDiameter: CGFloat = 78
    private let maximumDiameter: CGFloat = 150

    private var femaleValue: Double {
        guard femalePercentage.isFinite else { return 0 }
        return min(max(femalePercentage, 0), 100)
    }

    private var maleValue: Double { 100 - femaleValue }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("声音倾向参考")
                .font(.title3.weight(.bold))

            HStack(alignment: .center, spacing: 10) {
                PitchGenderScale(meanHz: meanPitchHz, rangeHz: pitchRangeHz)
                    .frame(width: 40)

                GeometryReader { proxy in
                    let largestDiameter = max(minimumDiameter, min(maximumDiameter, proxy.size.width - minimumDiameter - 18))
                    HStack(alignment: .center, spacing: 18) {
                        glassBubble(title: "Female", percentage: femaleValue, tint: Color.pink.opacity(0.12), maximumDiameter: largestDiameter)
                        glassBubble(title: "Male", percentage: maleValue, tint: Color.blue.opacity(0.10), maximumDiameter: largestDiameter)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(height: maximumDiameter)
            }
            .padding(22)
            .background(
                LinearGradient(
                    colors: [Color.pink.opacity(0.025), Color.blue.opacity(0.025)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "声音倾向参考，平均音高 \(meanPitchText)，样本音高范围 \(pitchRangeText)，Female \(percentageText(femaleValue))，Male \(percentageText(maleValue))"
            )
        }
    }

    private func glassBubble(
        title: LocalizedStringKey,
        percentage: Double,
        tint: Color,
        maximumDiameter: CGFloat
    ) -> some View {
        let diameter = minimumDiameter + (maximumDiameter - minimumDiameter) * CGFloat(percentage / 100)

        return VStack(spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(percentageText(percentage))
                .font(.system(size: 25, weight: .bold))
                .monospacedDigit()
                .minimumScaleFactor(0.72)
                .lineLimit(1)
        }
        .frame(width: diameter, height: diameter)
        .modifier(GlassBubbleModifier(tint: tint))
        .shadow(color: tint.opacity(0.08), radius: 14, y: 8)
        .accessibilityHidden(true)
    }

    private func percentageText(_ percentage: Double) -> String {
        percentage.formatted(.percent.scale(1).precision(.fractionLength(0)))
    }

    private var meanPitchText: String {
        guard let meanPitchHz, meanPitchHz.isFinite else { return "无可靠数据" }
        return "\(meanPitchHz.formatted(.number.precision(.fractionLength(0)))) Hz"
    }

    private var pitchRangeText: String {
        guard let pitchRangeHz else { return "无可靠数据" }
        return "\(pitchRangeHz.lowerBound.formatted(.number.precision(.fractionLength(0))))–\(pitchRangeHz.upperBound.formatted(.number.precision(.fractionLength(0)))) Hz"
    }
}

private struct PitchGenderScale: View {
    let meanHz: Double?
    let rangeHz: ClosedRange<Double>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let minimumHz = 50.0
    private let maximumHz = 350.0
    private let trackHeight: CGFloat = 180

    private var normalizedValue: CGFloat? {
        guard let meanHz, meanHz.isFinite, meanHz > 0 else { return nil }
        return normalized(meanHz)
    }

    private var normalizedRange: ClosedRange<CGFloat>? {
        guard let rangeHz,
              rangeHz.lowerBound.isFinite, rangeHz.upperBound.isFinite,
              rangeHz.lowerBound > 0 else { return nil }
        return normalized(rangeHz.lowerBound)...normalized(rangeHz.upperBound)
    }

    private func normalized(_ frequency: Double) -> CGFloat {
        CGFloat(min(max((frequency - minimumHz) / (maximumHz - minimumHz), 0), 1))
    }

    private func rangeFrame(in size: CGSize, range: ClosedRange<CGFloat>) -> CGRect {
        let top = (1 - range.upperBound) * size.height
        let bottom = (1 - range.lowerBound) * size.height
        // A narrow or clipped range keeps a visible lens, centered on the real range.
        let height = min(size.height, max(8, bottom - top))
        let originY = min(max(0, (top + bottom - height) / 2), size.height - height)
        return CGRect(x: (size.width - 30) / 2, y: originY, width: 30, height: height)
    }

    var body: some View {
        VStack(spacing: 7) {
            Text("350 Hz")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            GeometryReader { proxy in
                ZStack(alignment: .topLeading) {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    // Keep the upper band neutral, then blend into the female tint near 300 Hz.
                                    .init(color: Color.primary.opacity(0.045), location: 0),
                                    .init(color: Color.primary.opacity(0.045), location: 0.08),
                                    .init(color: Color.pink.opacity(0.07), location: 0.15),
                                    .init(color: Color.pink.opacity(0.16), location: 0.22),
                                    .init(color: Color.primary.opacity(0.04), location: 0.58),
                                    .init(color: Color.blue.opacity(0.14), location: 1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 18, height: proxy.size.height)
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                    if let normalizedRange {
                        let frame = rangeFrame(in: proxy.size, range: normalizedRange)
                        Color.clear
                            .frame(width: frame.width, height: frame.height)
                            .modifier(GlassRangeModifier())
                            // Move the finished glass surface, not only its content.
                            .position(x: frame.midX, y: frame.midY)
                    }

                    if let normalizedValue {
                        let markerY = min(max(1, (1 - normalizedValue) * proxy.size.height), proxy.size.height - 1)

                        Capsule(style: .continuous)
                            .fill(Color.secondary.opacity(0.80))
                            .frame(width: 20, height: 2)
                            .position(x: proxy.size.width / 2, y: markerY)

                        Text("AVG")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .minimumScaleFactor(0.7)
                            .fixedSize()
                            .position(x: -7, y: markerY)
                            .zIndex(2)
                    }
                }
                .animation(reduceMotion ? nil : .smooth(duration: 0.45), value: normalizedRange)
                .animation(reduceMotion ? nil : .smooth(duration: 0.45), value: normalizedValue)
            }
            .frame(height: trackHeight)

            Text("50 Hz")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .accessibilityHidden(true)
    }
}

private struct GlassRangeModifier: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 9, style: .continuous)

        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: shape)
                .overlay {
                    shape.strokeBorder(.primary.opacity(0.12), lineWidth: 0.75)
                }
        } else {
            content
                .background(.thinMaterial, in: shape)
                .overlay {
                    shape.strokeBorder(.primary.opacity(0.18), lineWidth: 0.75)
                }
        }
    }
}

private struct GlassBubbleModifier: ViewModifier {
    let tint: Color

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.tint(tint), in: Circle())
        } else {
            content
                .background(.thinMaterial, in: Circle())
                .overlay {
                    Circle().stroke(tint.opacity(0.35), lineWidth: 1)
                }
        }
    }
}

private struct CompactMetric {
    let title: LocalizedStringKey
    let value: String
    let unit: String
    let symbol: String
}

private struct ResultMetric: View {
    let title: LocalizedStringKey
    let value: String
    let unit: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 5) { number; suffix }
                VStack(alignment: .leading, spacing: 4) { number; suffix }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }

    private var number: some View {
        Text(value)
            .font(.title2.weight(.bold))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.72)
    }
    private var suffix: some View { Text(unit).font(.caption).foregroundStyle(.secondary) }
}
