//
//  LivePitchChartView.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/18.
//

import SwiftUI

struct LivePitchChartView: View {
    let samples: [LivePitchSample]
    let elapsedTime: TimeInterval
    let isRecording: Bool

    private var currentPitch: Double? {
        guard isRecording, let sample = samples.last,
              elapsedTime - sample.elapsedTime < 0.6,
              let pitch = sample.pitchHz, pitch.isFinite, pitch > 0 else { return nil }
        return pitch
    }

    private var accessibilityValue: String {
        if let currentPitch {
            return String(localized: "recording.timeline.currentPitch.a11y \(Int(currentPitch))")
        }
        return isRecording
            ? String(localized: "recording.timeline.noPitchDetected.a11y")
            : String(localized: "recording.timeline.notRecording.a11y")
    }

    var body: some View {
        let end = max(PitchTimeline.visibleSeconds, elapsedTime, samples.last?.elapsedTime ?? 0)
        PitchPlot(samples: samples, timeRange: (end - PitchTimeline.visibleSeconds)...end)
            .frame(height: 210)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("recording.timeline.a11y")
            .accessibilityValue(accessibilityValue)
    }
}

struct PitchPlot: View {
    let samples: [LivePitchSample]
    let timeRange: ClosedRange<TimeInterval>
    @ScaledMetric(relativeTo: .caption2) private var labelSize = 11.0
    @ScaledMetric(relativeTo: .caption2) private var labelWidth = 52.0

    var body: some View {
        Canvas { context, size in
            let plot = CGRect(
                x: labelWidth, y: labelSize,
                width: max(1, size.width - labelWidth - 12),
                height: max(1, size.height - labelSize * 4)
            )
            for (index, label) in ["600 Hz", "300", "150", "75"].enumerated() {
                let y = plot.minY + plot.height * CGFloat(index) / 3
                context.draw(
                    Text(verbatim: label)
                        .font(.system(size: labelSize).monospacedDigit())
                        .foregroundStyle(.secondary),
                    at: CGPoint(x: plot.minX - 8, y: y),
                    anchor: .trailing
                )
                var grid = Path()
                grid.move(to: CGPoint(x: plot.minX, y: y))
                grid.addLine(to: CGPoint(x: plot.maxX, y: y))
                context.stroke(grid, with: .color(.secondary.opacity(0.15)), lineWidth: 0.5)
            }

            let duration = max(0.001, timeRange.upperBound - timeRange.lowerBound)
            for index in 0...3 {
                let fraction = Double(index) / 3
                let seconds = timeRange.lowerBound + duration * fraction
                let label = seconds.formatted(.number.precision(.fractionLength(1))) + " s"
                context.draw(
                    Text(verbatim: label)
                        .font(.system(size: labelSize).monospacedDigit())
                        .foregroundStyle(.secondary),
                    at: CGPoint(x: plot.minX + plot.width * fraction, y: plot.maxY + labelSize * 1.6),
                    anchor: index == 0 ? .leading : (index == 3 ? .trailing : .center)
                )
            }

            var line = Path()
            var previousTime: TimeInterval?
            for sample in samples {
                guard let pitch = sample.pitchHz, pitch.isFinite, pitch > 0 else {
                    previousTime = nil
                    continue
                }
                let progress = (log2(min(max(pitch, 75), 600)) - log2(75)) / 3
                let point = CGPoint(
                    x: plot.minX + plot.width * (sample.elapsedTime - timeRange.lowerBound) / duration,
                    y: plot.minY + plot.height * (1 - progress)
                )
                if let previousTime, sample.elapsedTime - previousTime <= 0.4 {
                    line.addLine(to: point)
                } else {
                    line.move(to: point)
                }
                previousTime = sample.elapsedTime
            }
            context.clip(to: Path(plot.insetBy(dx: 0, dy: -1)))
            context.stroke(line, with: .color(.accentColor), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
        .clipped()
    }
}

/// A dedicated image layout includes every row, independent of the on-screen viewport.
struct PitchTimelineImage: View {
    let timeline: PitchTimeline

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("export.pitchImage.chart.title").font(.system(size: 26, weight: .semibold))
                    Text("export.pitchImage.chart.duration \(timeline.duration.formatted(.number.precision(.fractionLength(1))))")
                        .font(.system(size: 14)).foregroundStyle(.secondary)
                }
                Spacer()
                Text("common.brand.name").font(.system(size: 20, weight: .medium)).foregroundStyle(.secondary)
            }
            ForEach(timeline.imageRows) { row in
                PitchPlot(samples: row.samples, timeRange: row.range)
                    .frame(height: 150)
            }
            Text("export.pitchImage.chart.gapNote")
                .font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(width: 960)
        .background(.white)
        .environment(\.colorScheme, .light)
        .environment(\.dynamicTypeSize, .medium)
        .tint(Color(red: 0.20, green: 0.36, blue: 0.78))
    }
}

#if DEBUG
#Preview("Mock - Live Pitch", traits: .sizeThatFitsLayout) {
    LivePitchChartView(
        samples: DebugPreviewData.liveSamples,
        elapsedTime: 3.5,
        isRecording: true
    )
    .padding()
}

#Preview("Debug - Empty Pitch", traits: .sizeThatFitsLayout) {
    LivePitchChartView(samples: [], elapsedTime: 0, isRecording: false)
        .padding()
}

#Preview("Mock - Timeline Image", traits: .sizeThatFitsLayout) {
    PitchTimelineImage(timeline: PitchTimeline(result: DebugPreviewData.result))
}
#endif
