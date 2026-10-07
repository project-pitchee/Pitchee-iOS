//
//  MonitorViews.swift
//  Pitchee
//
//  Created by Ryo on 2026/10/5.
//

import SwiftUI

struct MonitoringHubView: View {
    var body: some View {
        List {
            Section {
                NavigationLink { PitchMonitorView() } label: {
                    Label(LocalizedStringKey(MonitorKind.pitch.titleKey), systemImage: MonitorKind.pitch.symbol)
                }
                .accessibilityIdentifier("monitor.openPitch")
                NavigationLink { SpectrumMonitorView() } label: {
                    Label(LocalizedStringKey(MonitorKind.spectrum.titleKey), systemImage: MonitorKind.spectrum.symbol)
                }
                .accessibilityIdentifier("monitor.openSpectrum")
            } footer: {
                Text("monitor.hub.description")
            }
        }
        .navigationTitle("monitor.screen.title")
    }
}

struct SpectrumMonitorView: View {
    @State private var model = makeMonitorModel(kind: .spectrum)
    var body: some View { MonitorPage(model: model) }
}

struct PitchMonitorView: View {
    @State private var model = makeMonitorModel(kind: .pitch)
    var body: some View { MonitorPage(model: model) }
}

@MainActor
private func makeMonitorModel(kind: MonitorKind) -> MonitorViewModel {
    #if DEBUG
    if ProcessInfo.processInfo.arguments.contains("-monitor-preview-data") {
        return .preview(kind: kind)
    }
    #endif
    return MonitorViewModel(kind: kind)
}

/// The destination renders the instrument; its controls are presented by the tab view.
private struct MonitorPage: View {
    let model: MonitorViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.monitorAccessoryState) private var accessoryState
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showsHelp = false

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width >= 700 && !dynamicTypeSize.isAccessibilitySize
            ScrollView {
                if wide {
                    HStack(alignment: .top, spacing: 40) {
                        MonitorReadout(model: model)
                            .frame(width: 240, alignment: .leading)
                        MonitorInstrument(model: model, height: max(180, min(340, geometry.size.height - 180)))
                    }
                    .padding(.vertical, 28)
                } else {
                    VStack(alignment: .leading, spacing: 28) {
                        MonitorReadout(model: model)
                        MonitorInstrument(model: model, height: dynamicTypeSize.isAccessibilitySize
                                          ? 240 : max(220, min(360, geometry.size.height * 0.42)))
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .padding(.horizontal, wide ? 32 : 24)
            .frame(maxWidth: 980)
            .frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .navigationTitle(LocalizedStringKey(model.kind.titleKey))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                MonitorWindowMenu(model: model)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("monitor.action.info", systemImage: "info.circle") { showsHelp = true }
                    .labelStyle(.iconOnly)
            }
        }
        .sheet(isPresented: $showsHelp) { MonitorHelpView(kind: model.kind) }
        .alert("monitor.error.title", isPresented: Binding(
            get: { !showsHelp && model.errorMessage != nil },
            set: { if !$0 { model.clearError() } }
        )) {
            Button("common.action.ok", role: .cancel) { model.clearError() }
        } message: {
            Text(verbatim: model.errorMessage ?? "")
        }
        .onAppear { accessoryState?.show(model) }
        .onDisappear {
            accessoryState?.hide(model)
            model.stopForLeaving()
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            switch phase {
            case .inactive: model.handleSceneInactive()
            case .background: model.pause()
            case .active: model.handleSceneActive()
            @unknown default: model.handleSceneInactive()
            }
        }
    }
}

private struct MonitorReadout: View {
    let model: MonitorViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var valueSize = 58.0

    private var frequency: Double? {
        model.currentFrequencyHz
    }

    private var secondaryValue: String {
        if model.kind == .spectrum {
            return model.currentSpectrumPeak.map { Double($0.amplitudeDBFS).formatted(.number.precision(.fractionLength(1))) } ?? "—"
        }
        guard let range = model.visiblePitchRange else { return "—" }
        let low = range.lowerBound
        let high = range.upperBound
        return "\(low.formatted(.number.precision(.fractionLength(0))))–\(high.formatted(.number.precision(.fractionLength(0))))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 20))
                : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 20))
            layout {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey(model.kind == .spectrum ? "monitor.spectrum.peak" : "monitor.pitch.current"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(verbatim: frequency.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "—")
                            .font(.system(size: valueSize, weight: .regular, design: .rounded).monospacedDigit())
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        Text("monitor.unit.hertz")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("monitor.frequency")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey(model.kind == .pitch ? "monitor.pitch.windowRange" : "monitor.spectrum.peakLevel"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(verbatim: secondaryValue)
                            .font(.system(.title3, design: .rounded).monospacedDigit())
                            .minimumScaleFactor(0.75)
                            .lineLimit(1)
                        Text(LocalizedStringKey(model.kind == .pitch ? "monitor.unit.hertz" : "monitor.unit.dbfs"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
            MonitorFrequencyGauge(frequency: frequency, kind: model.kind)
                .frame(height: 64)
        }
    }
}

private struct MonitorInstrument: View {
    let model: MonitorViewModel
    let height: CGFloat

    private var emptyKey: String? {
        if model.isBusy { return "monitor.status.preparing" }
        if !model.hasAudio { return model.state == .live ? "monitor.signal.waiting" : "monitor.signal.waitingHint" }
        if model.kind == .pitch && model.visiblePitchRange == nil {
            return "monitor.signal.unvoiced"
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                Group {
                    switch model.kind {
                    case .spectrum:
                        MonitorSpectrumPlot(frame: model.currentSpectrum)
                    case .pitch:
                        MonitorPitchPlot(samples: model.visiblePitchSamples,
                                         timeRange: model.visibleRange,
                                         cursorTime: model.cursorTime)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(LocalizedStringKey(
                    model.kind == .spectrum ? "monitor.spectrum.chart.a11y" : "monitor.pitch.chart.a11y"
                ))
                .accessibilityValue(Text("monitor.chart.range.a11y \(monitorSeconds(model.visibleRange.lowerBound)) \(monitorSeconds(model.visibleRange.upperBound)) \(monitorSeconds(model.cursorTime))"))

                if let emptyKey {
                    Text(LocalizedStringKey(emptyKey))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(uiColor: .systemBackground))
                        .padding(.leading, 28)
                        .padding(.horizontal, 28)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: height)

            if model.hasAudio {
                MonitorTimelineControl(model: model)
            }
            Text(LocalizedStringKey(model.kind == .pitch ? "monitor.pitch.readoutHint" : "monitor.spectrum.readoutHint"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct MonitorTimelineControl: View {
    let model: MonitorViewModel

    private var sliderRange: ClosedRange<Double> {
        model.availableRange.lowerBound...max(model.availableRange.lowerBound + 0.001,
                                             model.availableRange.upperBound)
    }
    var body: some View {
        VStack(spacing: 0) {
            Slider(value: Binding(
                get: { min(sliderRange.upperBound, max(sliderRange.lowerBound, model.cursorTime)) },
                set: { model.seek(to: $0) }
            ), in: sliderRange) {
                Text("monitor.browse.title")
            } onEditingChanged: { editing in
                if editing { model.pause() }
            }
            .tint(Color.pitcheeAccent)
            .disabled(model.isBusy)
            .accessibilityValue(Text("monitor.position.a11y \(monitorSeconds(model.cursorTime))"))
            .accessibilityHint("monitor.browse.hint")
            .accessibilityIdentifier("monitor.seek")
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: monitorClock(model.availableRange.lowerBound))
                Spacer(minLength: 12)
                Text(verbatim: monitorClock(model.availableRange.upperBound))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)

        }
    }
}

private struct MonitorWindowMenu: View {
    let model: MonitorViewModel

    private var selectedWindowLabel: LocalizedStringKey {
        switch model.windowDuration {
        case 5: "monitor.window.five"
        case 30: "monitor.window.thirty"
        default: "monitor.window.ten"
        }
    }

    var body: some View {
        Menu {
            Picker("monitor.window.title", selection: Binding(
                get: { model.windowDuration }, set: { model.setWindowDuration($0) }
            )) {
                Text("monitor.window.five").tag(5.0)
                Text("monitor.window.ten").tag(10.0)
                Text("monitor.window.thirty").tag(30.0)
            }
        } label: {
            Label {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("monitor.window.title")
                        .font(.caption2)
                    Text(selectedWindowLabel)
                        .font(.subheadline.monospacedDigit())
                }
            } icon: {
                Image(systemName: "clock")
            }
        }
        .disabled(model.isBusy)
        .accessibilityLabel("monitor.window.title")
        .accessibilityValue(Text(selectedWindowLabel))
        .accessibilityIdentifier("monitor.windowDuration")
    }
}

private struct MonitorHelpView: View {
    let kind: MonitorKind
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Label(LocalizedStringKey(kind == .spectrum ? "monitor.spectrum.readoutHint" : "monitor.pitch.readoutHint"),
                      systemImage: kind.symbol)
                Label("monitor.replay.note", systemImage: "play.circle")
                Label("monitor.browse.hint", systemImage: "gobackward.5")
                Label("monitor.retention.note", systemImage: "clock.arrow.circlepath")
            }
            .font(.subheadline)
            .navigationTitle("monitor.action.info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.action.done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private func monitorSeconds(_ seconds: Double) -> String {
    max(0, seconds).formatted(.number.precision(.fractionLength(1)))
}

private func monitorClock(_ seconds: Double) -> String {
    let tenths = Int((max(0, seconds) * 10).rounded())
    return String(format: "%02d:%02d.%d", tenths / 600, (tenths / 10) % 60, tenths % 10)
}

#if DEBUG
/// Opt-in simulator review routes keep visual checks independent of navigation and microphone access.
struct MonitorReviewModifier: ViewModifier {
    private let arguments = ProcessInfo.processInfo.arguments

    func body(content: Content) -> some View {
        if arguments.contains("-monitor-review-pitch") || arguments.contains("-monitor-review-spectrum") {
            content
                .tint(Color.pitcheeAccent)
                .preferredColorScheme(arguments.contains("-monitor-review-dark") ? .dark : .light)
                .environment(\.dynamicTypeSize, arguments.contains("-monitor-review-large-text") ? .accessibility2 : .large)
        } else {
            content
        }
    }
}

private struct MonitorScreenPreview: View {
    let model: MonitorViewModel
    @State private var accessoryState = MonitorAccessoryState()

    var body: some View {
        TabView {
            NavigationStack { MonitorPage(model: model) }
                .tabItem { Label("practice.hub.tab", systemImage: "figure.mind.and.body") }
        }
        .modifier(TabBarAccessory(isVisible: accessoryState.model != nil) {
            if let model = accessoryState.model { MonitorAccessoryContent(model: model) }
        })
        .environment(\.monitorAccessoryState, accessoryState)
        .tint(Color.pitcheeAccent)
    }
}

#Preview("Pitch · Ready") {
    MonitorScreenPreview(model: MonitorViewModel(kind: .pitch))
}
#Preview("Pitch · Paused") {
    MonitorScreenPreview(model: .preview(kind: .pitch))
}
#Preview("Spectrum · Paused") {
    MonitorScreenPreview(model: .preview(kind: .spectrum))
}
#Preview("Spectrum · Dark") {
    MonitorScreenPreview(model: .preview(kind: .spectrum))
        .preferredColorScheme(.dark)
}
#Preview("Pitch · Large Text") {
    MonitorScreenPreview(model: .preview(kind: .pitch))
        .environment(\.dynamicTypeSize, .accessibility2)
}
#endif
