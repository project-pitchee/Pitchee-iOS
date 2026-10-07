//
//  MonitorFrequencyGauge.swift
//  Pitchee
//
//  Created by Ryo on 2026/10/5.
//

import SwiftUI

/// A compact frequency ruler that shares the charts' logarithmic scale.
/// Its pointer represents a real, in-range measurement and disappears for gaps.
struct MonitorFrequencyGauge: View {
    let frequency: Double?
    let kind: MonitorKind

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        ZStack {
            // Only the pointer depends on the live measurement. Keep label
            // resolution, collision detection, and tick layout in a stable view.
            MonitorFrequencyRuler(kind: kind)
            Canvas { context, size in
                let inset = 6.0
                let width = max(1, Double(size.width) - inset * 2)
                let baseline = 29.0
                let increasedContrast = contrast == .increased
                let scale = MonitorGaugeScale(kind: kind)
                let range = scale.range
                guard let frequency, frequency.isFinite, range.contains(frequency) else { return }
                let x = scale.position(for: frequency, width: width, inset: inset)
                var pointer = Path()
                pointer.move(to: CGPoint(x: x, y: 10))
                pointer.addLine(to: CGPoint(x: x, y: baseline + 4))
                context.stroke(pointer, with: .color(.pitcheeAccent),
                               style: StrokeStyle(lineWidth: increasedContrast ? 2 : 1.5, lineCap: .round))

                var arrow = Path()
                arrow.move(to: CGPoint(x: x - 4, y: 3))
                arrow.addLine(to: CGPoint(x: x + 4, y: 3))
                arrow.addLine(to: CGPoint(x: x, y: 9))
                arrow.closeSubpath()
                context.fill(arrow, with: .color(.pitcheeAccent))
            }
        }
        .frame(height: 64)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(LocalizedStringKey(kind == .pitch ? "monitor.pitch.current" : "monitor.spectrum.peak"))
        .accessibilityValue(Text(verbatim: accessibilityDescription))
        .accessibilityIdentifier(kind == .pitch ? "monitor.pitchGauge" : "monitor.spectrumGauge")
    }

    private var accessibilityDescription: String {
        let hertz = String(localized: "monitor.unit.hertz")
        let current: String
        if let frequency, frequency.isFinite, frequency > 0 {
            current = "\(frequency.formatted(.number.precision(.fractionLength(1)))) \(hertz)"
        } else {
            current = kind == .pitch ? String(localized: "monitor.signal.unvoiced")
                : String(localized: "monitor.signal.noPeak")
        }
        let range = MonitorGaugeScale(kind: kind).range
        return "\(current). \(Int(range.lowerBound).formatted())–\(Int(range.upperBound).formatted()) \(hertz)"
    }
}

private struct MonitorFrequencyRuler: View {
    let kind: MonitorKind

    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .caption2) private var scaledLabelSize = 11.0

    var body: some View {
        Canvas { context, size in
            let inset = 6.0
            let width = max(1, Double(size.width) - inset * 2)
            let baseline = 29.0
            let increasedContrast = contrast == .increased
            let labelSize = min(14, max(10, scaledLabelSize))
            let scale = MonitorGaugeScale(kind: kind)
            let range = scale.range
            let majorTicks = scale.majorTicks
            let majorPositions = majorTicks.map { scale.position(for: $0, width: width, inset: inset) }

            var rule = Path()
            rule.move(to: CGPoint(x: inset, y: baseline))
            rule.addLine(to: CGPoint(x: inset + width, y: baseline))
            context.stroke(rule, with: .color(.primary.opacity(increasedContrast ? 0.4 : 0.18)),
                           lineWidth: 0.5)

            var minorMarks = Path()
            var majorMarks = Path()
            var lastMinorX = -Double.infinity
            // Decimal subdivisions preserve the scale's physical meaning.
            // Sparse marks are omitted only when there is no visual room.
            for decade in [10.0, 100.0, 1_000.0] {
                for multiplier in 1...9 {
                    let tick = decade * Double(multiplier)
                    guard range.contains(tick) else { continue }
                    let x = scale.position(for: tick, width: width, inset: inset)
                    if majorTicks.contains(tick) {
                        majorMarks.move(to: CGPoint(x: x, y: baseline - 13))
                        majorMarks.addLine(to: CGPoint(x: x, y: baseline))
                    } else if x - lastMinorX >= 4,
                              !majorPositions.contains(where: { abs($0 - x) < 4 }) {
                        minorMarks.move(to: CGPoint(x: x, y: baseline - 6))
                        minorMarks.addLine(to: CGPoint(x: x, y: baseline))
                        lastMinorX = x
                    }
                }
            }
            context.stroke(minorMarks, with: .color(.primary.opacity(increasedContrast ? 0.4 : 0.2)),
                           lineWidth: 0.5)
            context.stroke(majorMarks, with: .color(.primary.opacity(increasedContrast ? 0.7 : 0.42)),
                           lineWidth: increasedContrast ? 1 : 0.75)

            var occupiedLabelBounds: [CGRect] = []
            for tick in scale.labelPriority {
                let label = context.resolve(
                    Text(verbatim: scale.tickLabel(tick))
                        .font(.system(size: labelSize, weight: .regular, design: .rounded).monospacedDigit())
                        .foregroundColor(.secondary)
                )
                let labelDimensions = label.measure(in: CGSize(width: CGFloat.infinity, height: CGFloat.infinity))
                let x = scale.position(for: tick, width: width, inset: inset)
                let labelX = min(max(inset, x - labelDimensions.width / 2), inset + width - labelDimensions.width)
                let bounds = CGRect(x: labelX, y: baseline + 10,
                                    width: labelDimensions.width, height: labelDimensions.height)
                guard !occupiedLabelBounds.contains(where: {
                    $0.insetBy(dx: -7, dy: 0).intersects(bounds)
                }) else { continue }
                context.draw(label, at: CGPoint(x: bounds.midX, y: bounds.minY), anchor: .top)
                occupiedLabelBounds.append(bounds)
            }
        }
    }
}

private struct MonitorGaugeScale {
    let kind: MonitorKind

    var range: ClosedRange<Double> {
        kind == .pitch ? 50...1_000 : MonitorSpectrumFrame.frequencyRange
    }

    var majorTicks: [Double] {
        kind == .pitch ? [50, 100, 200, 500, 1_000] : [40, 100, 500, 1_000, 4_000, 8_000]
    }

    // Endpoints always have priority; the central reference comes next when
    // a narrow canvas or larger type requires fewer intermediate labels.
    var labelPriority: [Double] {
        kind == .pitch ? [50, 1_000, 200, 100, 500] : [40, 8_000, 1_000, 100, 4_000, 500]
    }

    func position(for frequency: Double, width: Double, inset: Double) -> Double {
        inset + width * log(frequency / range.lowerBound) / log(range.upperBound / range.lowerBound)
    }

    func tickLabel(_ frequency: Double) -> String {
        frequency >= 1_000 ? "\(Int(frequency / 1_000))k" : Int(frequency).formatted()
    }
}
