//
//  AccessibilitySupport.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/30.
//

import SwiftUI
import Accessibility

extension EnvironmentValues {
    var pitcheeAssistiveAccessEnabled: Bool {
        if #available(iOS 18.0, macOS 15.0, *) {
            return accessibilityAssistiveAccessEnabled
        }
        return false
    }
}

/// Keeps related values side by side at standard sizes and in reading order
/// vertically when the user needs accessibility text sizes.
struct AccessibleStack<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.pitcheeAssistiveAccessEnabled) private var assistiveAccess
    var horizontalAlignment: VerticalAlignment = .center
    var spacing: CGFloat = 12
    @ViewBuilder let content: () -> Content

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize || assistiveAccess
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
            : AnyLayout(HStackLayout(alignment: horizontalAlignment, spacing: spacing))
        layout { content() }
    }
}

struct AccessiblePickerStyle: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.pitcheeAssistiveAccessEnabled) private var assistiveAccess

    func body(content: Content) -> some View {
        if dynamicTypeSize.isAccessibilitySize || assistiveAccess {
            content.pickerStyle(.menu)
        } else {
            content.pickerStyle(.segmented)
        }
    }
}

/// Accessibility chart data for the live pitch graph. Keeping this adapter
/// separate from the Canvas renderer lets VoiceOver inspect every voiced
/// segment without changing the established visual chart.
struct PitchChartDescriptor {
    let snapshot: PitchAccessibilitySnapshot

    func makeChartDescriptor() -> AXChartDescriptor {
        AXChartDescriptor(
            __title: String(localized: "recording.timeline.a11y"),
            summary: nil,
            xAxisDescriptor: xAxis,
            yAxisDescriptor: yAxis,
            series: series
        )
    }

    func updateChartDescriptor(_ descriptor: AXChartDescriptor) {
        descriptor.xAxis = xAxis
        descriptor.yAxis = yAxis
        descriptor.series = series
    }

    private var xAxis: AXNumericDataAxisDescriptor {
        AXNumericDataAxisDescriptor(
            title: String(localized: "recording.timeline.timeAxis"), range: snapshot.range,
            gridlinePositions: [], valueDescriptionProvider: { value in
                value.formatted(.number.precision(.fractionLength(1)))
            }
        )
    }

    private var yAxis: AXNumericDataAxisDescriptor {
        AXNumericDataAxisDescriptor(
            title: String(localized: "recording.timeline.pitchAxis"), range: 75...600,
            gridlinePositions: [75, 150, 300, 600], valueDescriptionProvider: { value in
                value.formatted(.number.precision(.fractionLength(0)))
            }
        )
    }

    private var series: [AXDataSeriesDescriptor] {
        snapshot.voicedSegments.map { segment in
            AXDataSeriesDescriptor(
                name: String(localized: "recording.timeline.series"),
                isContinuous: segment.count > 1,
                dataPoints: segment.compactMap { sample in
                    guard let pitch = sample.pitchHz, pitch.isFinite, pitch > 0 else { return nil }
                    return AXDataPoint(x: sample.elapsedTime, y: pitch)
                }
            )
        }
    }
}
