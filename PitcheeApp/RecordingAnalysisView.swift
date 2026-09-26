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
                        Label("analysis.emptyState.noResult.title", systemImage: "waveform.badge.exclamationmark")
                    } description: {
                        Text(viewModel.errorMessage ?? String(localized: "analysis.emptyState.noResult.description"))
                    }
                    .padding(.top, 60)
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(viewModel.isAnalyzing
            ? String(localized: "analysis.navigation.analyzing")
            : String(localized: "analysis.navigation.result"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isAnalyzing)
        .toolbar {
            if let result = viewModel.result, !viewModel.isAnalyzing {
                ToolbarItem(placement: .topBarTrailing) {
                    RecordingExportButton(
                        result: result,
                        volumeStatistics: viewModel.volumeStatistics
                    )
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
                Text("analysis.progress.title")
                    .font(.title2.weight(.bold))
                Text("analysis.progress.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ProgressView().controlSize(.large)
            Label("analysis.progress.privacyNote", systemImage: "lock.shield")
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
    private let pitchStatistics: RecordingPitchStatistics

    @State private var showsVoiceDetails = false
    @State private var selectedSuggestion: ResultSuggestion?
    @State private var selectedResource: ResultResource?

    init(
        result: PitcheeAnalysisResult,
        volumeStatistics: RecordingVolumeStatistics?,
        saveError: String?
    ) {
        self.result = result
        self.volumeStatistics = volumeStatistics
        self.saveError = saveError
        self.pitchStatistics = RecordingPitchStatistics(pitch: result.f0)
    }

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

            voiceProfileSection

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

    private var voiceProfileSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("analysis.voiceProfile.title")
                    .font(.title3.weight(.bold))

                Spacer(minLength: 8)

                Button {
                    showsVoiceDetails = true
                } label: {
                    HStack(spacing: 4) {
                        Text("analysis.voiceDetails.action")
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("analysis.voiceDetails.action.a11y")
            }

            VoiceProfileReferenceChart(
                femalePercentage: result.vfp.vfpStandardScore,
                meanPitchHz: result.f0.meanHz,
                pitchRangeHz: pitchRangeHz
            )
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
                Text("analysis.suggestions.title")
                    .font(.title2.weight(.bold))
                Text("analysis.suggestions.subtitle")
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
                Text("analysis.resources.title")
                    .font(.title2.weight(.bold))
                Text("analysis.resources.subtitle")
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
                title: needsLongerRecording ? String(localized: "analysis.suggestions.shortRecording.title") : String(localized: "analysis.suggestions.adequateRecording.title"),
                detail: needsLongerRecording
                    ? String(localized: "analysis.suggestions.shortRecording.subtitle")
                    : String(localized: "analysis.suggestions.adequateRecording.subtitle"),
                symbol: "timer",
                tint: .blue,
                expandedDetail: needsLongerRecording
                    ? String(localized: "analysis.suggestions.shortRecording.description")
                    : String(localized: "analysis.suggestions.adequateRecording.description")
            ),
            ResultSuggestion(
                id: "naturalness",
                title: naturalnessNeedsWork ? String(localized: "analysis.suggestions.unnaturalSpeech.title") : String(localized: "analysis.suggestions.naturalSpeech.title"),
                detail: naturalnessNeedsWork
                    ? String(localized: "analysis.suggestions.unnaturalSpeech.subtitle")
                    : String(localized: "analysis.suggestions.naturalSpeech.subtitle"),
                symbol: "waveform",
                tint: .orange,
                expandedDetail: naturalnessNeedsWork
                    ? String(localized: "analysis.suggestions.unnaturalSpeech.description")
                    : String(localized: "analysis.suggestions.naturalSpeech.description")
            )
        ]
    }

    private var resources: [ResultResource] {
        [
            ResultResource(
                id: "naturalness-video",
                title: String(localized: "analysis.resources.naturalnessTraining.title"),
                detail: String(localized: "analysis.resources.naturalnessTraining.subtitle"),
                badge: "01:09",
                symbol: "play.fill",
                tint: .blue,
                body: String(localized: "analysis.resources.naturalnessTraining.description")
            ),
            ResultResource(
                id: "voice-research",
                title: String(localized: "analysis.resources.voiceResearch.title"),
                detail: String(localized: "analysis.resources.voiceResearch.subtitle"),
                badge: String(localized: "analysis.resources.readBadge"),
                symbol: "doc.text.image",
                tint: .purple,
                body: String(localized: "analysis.resources.voiceResearch.description")
            )
        ]
    }

    private var voiceDetailsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("analysis.voiceDetails.metrics.title")
                            .font(.title3.weight(.bold))
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                            ResultMetric(title: "common.metric.naturalness.title", value: scoreText(result.naturalness.score), unit: String(localized: "common.unit.pointsOutOf100"), symbol: "leaf")
                            ResultMetric(title: "common.metric.standardScore.title", value: scoreText(result.vfp.vfpStandardScore), unit: String(localized: "common.unit.pointsOutOf100"), symbol: "slider.horizontal.3")
                            ResultMetric(title: "common.metric.speechDuration.title", value: result.vad.speechSeconds.formatted(.number.precision(.fractionLength(1))), unit: String(localized: "common.unit.seconds"), symbol: "bubble.left")
                        }
                    }

                    recordingStatistics
                }
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .padding(24)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("analysis.voiceDetails.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.action.done") { showsVoiceDetails = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var scoreSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("common.metric.compositeScore.title")
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
                .accessibilityLabel("analysis.score.explanation.a11y")
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(scoreText(result.composite.finalScore))
                    .font(.system(size: 78, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.accentColor)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                Text("common.unit.pointsOutOf100")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }

            ProgressView(value: scoreProgress, total: 1)
                .tint(Color.accentColor)
                .scaleEffect(x: 1, y: 1.35, anchor: .center)
                .accessibilityLabel("analysis.score.progress.a11y")
                .accessibilityValue("analysis.score.progress.a11yValue \(scoreText(result.composite.finalScore))")

            Text(scoreHeadline)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("analysis.score.summary.a11y \(scoreText(result.composite.finalScore))")
    }

    private var scoreProgress: Double {
        min(max(result.composite.finalScore / 100, 0), 1)
    }

    private var scoreHeadline: String {
        switch result.composite.finalScore {
        case 90...: return String(localized: "analysis.score.headlineHigh")
        case 70..<90: return String(localized: "analysis.score.headlineMedium")
        default: return String(localized: "analysis.score.headlineLow")
        }
    }

    private var recordingStatistics: some View {
        VStack(alignment: .leading, spacing: 24) {
            compactStatisticsSection(title: "analysis.statistics.pitch.title", metrics: pitchMetrics)

            compactStatisticsSection(title: "analysis.statistics.volume.title", metrics: volumeMetrics)

            Text("analysis.statistics.volume.note")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var pitchRangeHz: ClosedRange<Double>? {
        guard let low = pitchStatistics.low5Hz,
              let high = pitchStatistics.high95Hz else { return nil }
        return low...high
    }

    private var pitchMetrics: [CompactMetric] {
        let dominantBand = dominantPitchBand(pitchStatistics)
        return [
            CompactMetric(title: "common.metric.meanPitch.title", value: metricNumber(pitchStatistics.averageHz), unit: String(localized: "common.unit.hertz"), symbol: "waveform.path"),
            CompactMetric(title: "common.metric.medianPitch.title", value: metricNumber(pitchStatistics.medianHz), unit: String(localized: "common.unit.hertz"), symbol: "equal"),
            CompactMetric(title: "common.metric.corePitchRange.title", value: pitchRangeText(pitchStatistics), unit: String(localized: "common.unit.hertzPercentileRange"), symbol: "arrow.left.and.right"),
            CompactMetric(title: "analysis.statistics.dominantPitchBand.label", value: dominantBand.name, unit: dominantBand.percentage, symbol: "scope")
        ]
    }

    private var volumeMetrics: [CompactMetric] {
        [
            CompactMetric(title: "common.metric.environmentNoiseFloor.title", value: metricNumber(volumeStatistics?.environmentDBFS), unit: String(localized: "common.unit.dbfs"), symbol: "wind"),
            CompactMetric(title: "analysis.statistics.averageVolume.label", value: metricNumber(volumeStatistics?.averageDBFS), unit: volumeUnit(volumeStatistics?.averageDBFS), symbol: "speaker.wave.2"),
            CompactMetric(title: "analysis.statistics.medianVolume.label", value: metricNumber(volumeStatistics?.medianDBFS), unit: volumeUnit(volumeStatistics?.medianDBFS), symbol: "equal"),
            CompactMetric(title: "analysis.statistics.volumeRange.label", value: volumeRangeText, unit: String(localized: "common.unit.dbfsPercentileRange"), symbol: "arrow.left.and.right")
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
        guard let value else { return String(localized: "common.placeholder.noValue") }
        return value.formatted(.number.precision(.fractionLength(1)))
    }

    private func pitchRangeText(_ statistics: RecordingPitchStatistics) -> String {
        guard let low = statistics.low5Hz,
              let high = statistics.high95Hz else { return String(localized: "common.placeholder.noValue") }
        return "\(metricNumber(low))–\(metricNumber(high))"
    }

    private func dominantPitchBand(
        _ statistics: RecordingPitchStatistics
    ) -> (name: String, percentage: String) {
        guard statistics.medianHz != nil else { return (String(localized: "common.placeholder.noValue"), "") }
        let bands = [
            (String(localized: "analysis.pitchBands.veryHigh"), statistics.veryHighPercentage),
            (String(localized: "analysis.pitchBands.feminine"), statistics.femininePercentage),
            (String(localized: "analysis.pitchBands.androgynous"), statistics.androgynousPercentage),
            (String(localized: "analysis.pitchBands.masculine"), statistics.masculinePercentage),
            (String(localized: "analysis.pitchBands.veryLow"), statistics.veryLowPercentage)
        ]
        guard let dominant = bands.max(by: { $0.1 < $1.1 }) else { return (String(localized: "common.placeholder.noValue"), "") }
        return (
            dominant.0,
            dominant.1.formatted(.percent.precision(.fractionLength(0)))
        )
    }

    private func volumeUnit(_ value: Double?) -> String {
        guard let value,
              let environment = volumeStatistics?.environmentDBFS else { return String(localized: "common.unit.dbfs") }
        let delta = (value - environment).formatted(
            .number
                .sign(strategy: .always())
                .precision(.fractionLength(1))
        )
        return String(localized: "common.unit.dbfsWithDelta \(delta)")
    }

    private var volumeRangeText: String {
        guard let low = volumeStatistics?.low5DBFS,
              let high = volumeStatistics?.high95DBFS else { return String(localized: "common.placeholder.noValue") }
        return "\(metricNumber(low))–\(metricNumber(high))"
    }

    private func scoreText(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }

}

private struct ScoreExplanationView: View {
    let result: PitcheeAnalysisResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                intro
                commonFormulaSection
                currentRuleSection
                otherRulesSection
            }
            .frame(maxWidth: 600, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("scoring.explanation.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("scoring.explanation.intro.title")
                .font(.title2.weight(.bold))
            Text("scoring.explanation.intro.description")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var commonFormulaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("scoring.baseFormula.title")
                .font(.title3.weight(.bold))
            Text("scoring.baseFormula.subtitle")
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
            Text("scoring.baseFormula.note")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var currentRuleSection: some View {
        let rule = currentRuleDocumentation

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("scoring.currentRule.title")
                    .font(.title3.weight(.bold))
                Text("scoring.currentRule.badge")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
            }
            Text(rule.guidance)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            ruleDetail(String(localized: "scoring.ruleDetail.condition"), text: rule.condition)
            ruleDetail(String(localized: "scoring.ruleDetail.formula"), text: nil)
            FormulaBlock(lines: rule.formulas)
            ruleDetail(String(localized: "scoring.ruleDetail.result"), text: rule.result)
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
            Label("scoring.otherRules.title", systemImage: "list.bullet.rectangle")
                .font(.subheadline.weight(.semibold))
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var currentRuleDocumentation: ScoreRuleDocumentation {
        scoreRuleDocumentation.first { $0.id == result.composite.rule } ?? scoreRuleDocumentation[0]
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
        title: String(localized: "scoring.rules.continuous.title"),
        guidance: String(localized: "scoring.rules.continuous.description"),
        condition: String(localized: "scoring.rules.continuous.condition"),
        formulas: [#"\mathrm{Final} = \mathrm{Base}"#],
        result: String(localized: "scoring.rules.continuous.result")
    ),
    ScoreRuleDocumentation(
        id: "pass_boost",
        title: String(localized: "scoring.rules.passBoost.title"),
        guidance: String(localized: "scoring.rules.passBoost.description"),
        condition: String(localized: "scoring.rules.passBoost.condition"),
        formulas: [
            #"s_{F0} = \frac{F_0 - 165}{25}"#,
            #"s_N = \frac{\mathrm{Naturalness} - 80}{20}"#,
            #"s_S = \frac{\mathrm{Standard} - 50}{30}"#,
            #"\mathrm{strength} = \min(s_{F0}, s_N, s_S, 1)"#,
            #"\mathrm{promoted} = 60 + 40\,\mathrm{strength}"#,
            #"\mathrm{Final} = \max(\mathrm{Base}, \mathrm{promoted})"#
        ],
        result: String(localized: "scoring.rules.passBoost.result")
    ),
    ScoreRuleDocumentation(
        id: "high_f0_stylized_cap",
        title: String(localized: "scoring.rules.highF0StylizedCap.title"),
        guidance: String(localized: "scoring.rules.highF0StylizedCap.description"),
        condition: String(localized: "scoring.rules.highF0StylizedCap.condition"),
        formulas: [#"\mathrm{Final} = \min(\mathrm{Base}, 30)"#],
        result: String(localized: "scoring.rules.highF0StylizedCap.result")
    ),
    ScoreRuleDocumentation(
        id: "low_f0_natural_cap",
        title: String(localized: "scoring.rules.lowF0NaturalCap.title"),
        guidance: String(localized: "scoring.rules.lowF0NaturalCap.description"),
        condition: String(localized: "scoring.rules.lowF0NaturalCap.condition"),
        formulas: [#"\mathrm{Final} = \min(\mathrm{Base}, 59)"#],
        result: String(localized: "scoring.rules.lowF0NaturalCap.result")
    ),
    ScoreRuleDocumentation(
        id: "low_f0_stylized_cap",
        title: String(localized: "scoring.rules.lowF0StylizedCap.title"),
        guidance: String(localized: "scoring.rules.lowF0StylizedCap.description"),
        condition: String(localized: "scoring.rules.lowF0StylizedCap.condition"),
        formulas: [#"\mathrm{Final} = \min(\mathrm{Base}, 20)"#],
        result: String(localized: "scoring.rules.lowF0StylizedCap.result")
    ),
    ScoreRuleDocumentation(
        id: "high_f0_male_cap",
        title: String(localized: "scoring.rules.highF0MaleCap.title"),
        guidance: String(localized: "scoring.rules.highF0MaleCap.description"),
        condition: String(localized: "scoring.rules.highF0MaleCap.condition"),
        formulas: [#"\mathrm{Final} = \min(\mathrm{Base}, 59)"#],
        result: String(localized: "scoring.rules.highF0MaleCap.result")
    ),
    ScoreRuleDocumentation(
        id: "f0_unavailable",
        title: String(localized: "scoring.rules.f0Unavailable.title"),
        guidance: String(localized: "scoring.rules.f0Unavailable.description"),
        condition: String(localized: "scoring.rules.f0Unavailable.condition"),
        formulas: [#"\mathrm{Final} = \mathrm{Standard}"#],
        result: String(localized: "scoring.rules.f0Unavailable.result")
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
            .navigationTitle("analysis.suggestionDetail.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.action.done") { dismiss() }
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
            .navigationTitle(
                resource.id == "voice-research"
                    ? String(localized: "analysis.resourceDetail.article.title")
                    : String(localized: "analysis.resourceDetail.video.title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.action.done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct VoiceProfileReferenceChart: View {
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
        HStack(alignment: .center, spacing: 10) {
            PitchGenderScale(meanHz: meanPitchHz, rangeHz: pitchRangeHz)
                .frame(width: 40)

            GeometryReader { proxy in
                let largestDiameter = max(minimumDiameter, min(maximumDiameter, proxy.size.width - minimumDiameter - 18))
                HStack(alignment: .center, spacing: 18) {
                    glassBubble(title: "analysis.voiceProfile.female.label", percentage: femaleValue, tint: Color.pink.opacity(0.12), maximumDiameter: largestDiameter)
                    glassBubble(title: "analysis.voiceProfile.male.label", percentage: maleValue, tint: Color.blue.opacity(0.10), maximumDiameter: largestDiameter)
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
            "analysis.voiceProfile.reference.a11y \(meanPitchText) \(pitchRangeText) \(percentageText(femaleValue)) \(percentageText(maleValue))"
        )
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
        guard let meanPitchHz, meanPitchHz.isFinite else { return String(localized: "analysis.voiceProfile.noData") }
        return "\(meanPitchHz.formatted(.number.precision(.fractionLength(0)))) Hz"
    }

    private var pitchRangeText: String {
        guard let pitchRangeHz else { return String(localized: "analysis.voiceProfile.noData") }
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
            Text("analysis.pitchScale.maxLabel")
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

                        Text("analysis.pitchScale.averageMarker")
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

            Text("analysis.pitchScale.minLabel")
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

#if DEBUG
#Preview("Mock - Result") {
    DebugAnalysisPreview(state: .completed) { model in
        NavigationStack { RecordingAnalysisView(viewModel: model) }
    }
}

#Preview("Mock - Analyzing") {
    DebugAnalysisPreview(state: .analyzing) { model in
        NavigationStack { RecordingAnalysisView(viewModel: model) }
    }
}

#Preview("Debug - No Result") {
    DebugAnalysisPreview(state: .idle) { model in
        NavigationStack { RecordingAnalysisView(viewModel: model) }
    }
}

#Preview("Mock - Result Save Error") {
    NavigationStack {
        RecordingResultView(
            result: DebugPreviewData.result,
            volumeStatistics: nil,
            saveError: String(localized: "analysis.error.resultSaveFailed")
        )
    }
}

#Preview("Mock - Score Explanation") {
    NavigationStack { ScoreExplanationView(result: DebugPreviewData.result) }
}
#endif
