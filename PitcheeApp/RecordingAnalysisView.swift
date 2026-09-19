//
//  RecordingAnalysisView.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/18.
//

import SwiftUI

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
        .navigationTitle(viewModel.isAnalyzing ? "正在分析" : "声音报告")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isAnalyzing)
        .toolbar {
            if let result = viewModel.result, !viewModel.isAnalyzing {
                ToolbarItem(placement: .topBarTrailing) {
                    PitchImageExportButton { PitchTimeline(result: result) }
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

    var body: some View {
        FoldAwareArrangementView(
            primary: { resultPane(overview) },
            secondary: { resultPane(details) },
            regular: { resultScroll(allContent) }
        )
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 28) {
            scoreSummary

            VoiceProfileReferenceChart(
                femalePercentage: result.vfp.vfpStandardScore,
                meanPitchHz: result.f0.meanHz,
                pitchRangeHz: pitchRangeHz
            )

            if let saveError {
                Label(saveError, systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
            }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 14) {
                Text("声音指标").font(.title3.weight(.bold))
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                    ResultMetric(title: "自然度", value: scoreText(result.naturalness.score), unit: "/ 100", symbol: "leaf")
                    ResultMetric(title: "标准评分", value: scoreText(result.vfp.vfpStandardScore), unit: "/ 100", symbol: "slider.horizontal.3")
                    ResultMetric(title: "有效语音", value: result.vad.speechSeconds.formatted(.number.precision(.fractionLength(1))), unit: "秒", symbol: "bubble.left")
                }
            }

            recordingStatistics
            explanationSection
            scoreExplanation
        }
    }

    private var allContent: some View {
        VStack(alignment: .leading, spacing: 28) {
            overview
            details
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

    private var scoreExplanation: some View {
        DisclosureGroup("评分如何得出") {
            VStack(alignment: .leading, spacing: 12) {
                Text("标准评分反映模型识别的女性向声音特征；综合评分结合标准评分、自然度和平均音高计算。它不代表声音的整体好坏。")
                Text("声音偏好只记录你的练习方向，当前不会切换评分模型。")
                if result.composite.limited, let cap = result.composite.cap {
                    Text("本次触发了评分上限规则，综合评分上限为 \(scoreText(cap)) 分。")
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.top, 12)
        }
        .font(.subheadline.weight(.medium))
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private var scoreSummary: some View {
        Text(scoreText(result.composite.finalScore))
            .font(.system(size: 88, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(Color.accentColor)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .contentTransition(.numericText())
            .accessibilityLabel("综合评分 \(scoreText(result.composite.finalScore)) 分，满分 100 分")
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
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
