//
//  ContentView.swift
//  Pitchee
//
//  Created by Lvy Zhan on 2026/6/12.
//

import SwiftData
import SwiftUI
import UIKit

struct ContentView: View {
    @AppStorage(AppStorageKey.onboardingCompletedVersion) private var completedOnboardingVersion = 0

    var body: some View {
        Group {
            if completedOnboardingVersion >= OnboardingFlow.currentVersion {
                MainTabView()
            } else {
                OnboardingView {
                    completedOnboardingVersion = OnboardingFlow.currentVersion
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: completedOnboardingVersion)
    }
}

private struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var recordingModel = AnalysisViewModel()
    @State private var selectedTab: AppTab = .trends
    @State private var showsRecordingAnalysis = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TrendsView {
                    selectedTab = .recording
                }
            }
            .tabItem {
                Label(AppTab.trends.title, systemImage: AppTab.trends.systemImage)
            }
            .tag(AppTab.trends)

            NavigationStack {
                RecordingView(viewModel: recordingModel, showsAnalysis: $showsRecordingAnalysis)
            }
            .tabItem {
                Label(AppTab.recording.title, systemImage: AppTab.recording.systemImage)
            }
            .tag(AppTab.recording)

            NavigationStack {
                PianoKeysView()
            }
            .tabItem {
                Label(AppTab.pianoKeys.title, systemImage: AppTab.pianoKeys.systemImage)
            }
            .tag(AppTab.pianoKeys)

            NavigationStack {
                AboutView()
            }
            .tabItem {
                Label(AppTab.about.title, systemImage: AppTab.about.systemImage)
            }
            .tag(AppTab.about)
        }
        .tint(.accentColor)
        .modifier(RecordingTabAccessory(
            isVisible: (selectedTab == .recording && !showsRecordingAnalysis)
                || recordingModel.isRecording || recordingModel.isRequestingPermission,
            viewModel: recordingModel,
            action: recordingAction
        ))
    }

    private func recordingAction() {
        if recordingModel.isAnalyzing {
            selectedTab = .recording
            showsRecordingAnalysis = true
            return
        }
        recordingModel.primaryButtonTapped(modelContext: modelContext)
        if recordingModel.isAnalyzing {
            selectedTab = .recording
            showsRecordingAnalysis = true
        }
    }
}

private enum AppTab: Hashable {
    case trends
    case recording
    case pianoKeys
    case about

    var title: LocalizedStringKey {
        switch self {
        case .trends:
            "insights.screen.title"
        case .recording:
            "recording.screen.title"
        case .pianoKeys:
            "piano.screen.title"
        case .about:
            "about.screen.title"
        }
    }

    var systemImage: String {
        switch self {
        case .trends:
            "chart.line.uptrend.xyaxis"
        case .recording:
            "waveform.badge.microphone"
        case .pianoKeys:
            "pianokeys"
        case .about:
            "info.circle"
        }
    }
}

private struct TrendsView: View {
    @Query(sort: \RecordingAssessment.recordedAt, order: .reverse)
    private var assessments: [RecordingAssessment]
    @AppStorage(AppStorageKey.openedDateKeys) private var openedDateKeys = ""

    /// Placeholder for a metric that has no value yet. Kept in one place so the
    /// empty-state comparison in `metricValue(value:tint:)` keeps matching.
    private static let noValue = String(localized: "common.placeholder.noValue")

    private let onRecordTapped: () -> Void

    init(onRecordTapped: @escaping () -> Void = {}) {
        self.onRecordTapped = onRecordTapped
    }

    var body: some View {
        List {
            Section {
                summaryMetrics
                .accessibilityElement(children: .combine)
            }

            metricRow(
                title: String(localized: "common.metric.compositeScore.title"),
                value: assessments.first.map { scoreText($0.finalScore) } ?? Self.noValue,
                tint: .blue,
                description: String(localized: "insights.metric.compositeScore.caption"),
                current: assessments.first?.finalScore,
                baseline: averages.finalScore.map(scoreText),
                baselineValue: averages.finalScore
            )

            metricRow(
                title: String(localized: "common.metric.naturalness.title"),
                value: assessments.first.map { scoreText($0.naturalnessScore) } ?? Self.noValue,
                tint: .orange,
                description: String(localized: "insights.metric.naturalness.caption"),
                current: assessments.first?.naturalnessScore,
                baseline: averages.naturalnessScore.map(scoreText),
                baselineValue: averages.naturalnessScore
            )

            metricRow(
                title: String(localized: "common.metric.meanPitch.title"),
                value: assessments.first?.meanPitchHz.map(scoreText) ?? Self.noValue,
                tint: .purple,
                description: String(localized: "insights.metric.meanPitch.caption"),
                current: assessments.first?.meanPitchHz,
                baseline: averages.meanPitchHz.map(scoreText),
                baselineValue: averages.meanPitchHz
            )

            metricRow(
                title: String(localized: "common.metric.speechDuration.title"),
                value: assessments.first.map { decimalText($0.speechSeconds) } ?? Self.noValue,
                tint: .green,
                description: String(localized: "insights.metric.speechDuration.caption"),
                current: assessments.first?.speechSeconds,
                baseline: averages.speechSeconds.map(decimalText),
                baselineValue: averages.speechSeconds
            )

            if assessments.isEmpty {
                Section {
                    Button("insights.emptyState.startFirstRecording", systemImage: "mic.fill", action: onRecordTapped)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("insights.screen.title")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if #available(iOS 27.1, *) {
                ToolbarItem(placement: .topBarPinnedTrailing) {
                    settingsLink
                }
                .axisBehavior(.verticalPreferred)
                .visibilityPriority(.high)
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    settingsLink
                }
            }
        }
        .onAppear(perform: recordTodayAsOpened)
    }

    private var openedDays: Int {
        openedDateKeys
            .split(separator: ",")
            .filter { !$0.isEmpty }
            .count
    }

    private var averages: RecordingAssessmentAverages {
        RecordingAssessmentAverages(assessments: Array(assessments.dropFirst()))
    }

    private var settingsLink: some View {
        NavigationLink {
            SettingsView()
        } label: {
            Label("settings.screen.title", systemImage: "person.crop.circle")
        }
    }

    private var summaryMetrics: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) {
                analysisCountStat
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .frame(height: 54)

                openedDaysStat
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)
            }

            VStack(alignment: .leading, spacing: 16) {
                analysisCountStat
                Divider()
                openedDaysStat
            }
        }
    }

    private var analysisCountStat: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(assessments.count.formatted())
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Text("insights.summary.analysisCount.title")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var openedDaysStat: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(openedDays.formatted())
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pink, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("common.unit.days")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.orange)
            }
            Text("insights.summary.openedDays.title")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func scoreText(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }

    private func decimalText(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }

    @ViewBuilder
    private func metricRow(
        title: String,
        value: String,
        tint: Color,
        description: String,
        current: Double?,
        baseline: String?,
        baselineValue: Double?
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            ViewThatFits(in: .horizontal) {
                metricDetails(
                    value: value,
                    tint: tint,
                    description: description,
                    current: current,
                    baseline: baseline,
                    baselineValue: baselineValue,
                    axis: .horizontal
                )
                metricDetails(
                    value: value,
                    tint: tint,
                    description: description,
                    current: current,
                    baseline: baseline,
                    baselineValue: baselineValue,
                    axis: .vertical
                )
            }
        }
        .padding(.vertical, 10)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private func metricDetails(
        value: String,
        tint: Color,
        description: String,
        current: Double?,
        baseline: String?,
        baselineValue: Double?,
        axis: Axis
    ) -> some View {
        if axis == .horizontal {
            HStack(alignment: .center, spacing: 16) {
                metricValue(value: value, tint: tint)
                metricDescription(
                    description: description,
                    current: current,
                    baseline: baseline,
                    baselineValue: baselineValue
                )
                Spacer(minLength: 0)
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                metricValue(value: value, tint: tint)
                metricDescription(
                    description: description,
                    current: current,
                    baseline: baseline,
                    baselineValue: baselineValue
                )
            }
        }
    }

    private func metricValue(value: String, tint: Color) -> some View {
        Text(value)
            .font(.system(.title, design: .rounded).weight(.bold))
            .foregroundStyle(value == Self.noValue ? Color(uiColor: .secondaryLabel) : tint)
            .minimumScaleFactor(0.65)
            .lineLimit(1)
            .frame(width: 108, height: 72)
            .background(
                Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
    }

    @ViewBuilder
    private func metricDescription(
        description: String,
        current: Double?,
        baseline: String?,
        baselineValue: Double?
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            trendIndicator(current: current, baseline: baselineValue)
                .font(.title3.weight(.semibold))

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let baseline {
                Text("insights.metric.baselineAverage.caption \(baseline)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private func trendIndicator(current: Double?, baseline: Double?) -> some View {
        if let current, let baseline {
            let change = current - baseline
            if abs(change) < 0.05 {
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
            } else if change > 0 {
                Image(systemName: "arrow.up")
                    .foregroundStyle(.red)
            } else {
                Image(systemName: "arrow.down")
                    .foregroundStyle(.green)
            }
        } else {
            Text(verbatim: Self.noValue)
                .foregroundStyle(.secondary)
        }
    }

    private func recordTodayAsOpened() {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        guard let year = components.year, let month = components.month, let day = components.day else {
            return
        }

        let todayKey = "\(year)-\(month)-\(day)"
        var dateKeys = Set(
            openedDateKeys
                .split(separator: ",")
                .map(String.init)
        )
        dateKeys.insert(todayKey)
        openedDateKeys = dateKeys.sorted().joined(separator: ",")
    }
}

private struct PianoKeysView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var soundEngine = PianoSoundEngine()
    @State private var activeNote: PianoNote?
    @State private var isVisible = false
    @State private var feedback = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ScrollView(showsIndicators: false) {
            noteGrid
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .environment(\.layoutDirection, .leftToRight)
        }
        .background {
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.08),
                    Color.purple.opacity(0.05),
                    Color(uiColor: .systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .navigationTitle("piano.screen.title")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isVisible = true
            soundEngine.prepare()
            feedback.prepare()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, isVisible {
                soundEngine.prepare()
                feedback.prepare()
            } else if phase != .active {
                soundEngine.stopAll()
                activeNote = nil
            }
        }
        .onDisappear {
            isVisible = false
            soundEngine.stopAll()
            activeNote = nil
        }
    }

    private var noteGrid: some View {
        // A piano keyboard is a physical object with a fixed orientation: the low
        // notes stay on the left even in right-to-left languages. Without this the
        // grid would fill from the trailing edge and the notes would read high to low.
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 132), spacing: 12)],
            spacing: 12
        ) {
            ForEach(PianoNote.allNotes) { note in
                PianoNoteButton(
                    note: note,
                    isActive: activeNote == note,
                    onTap: {
                        playOnce(note)
                    },
                    onSustainChanged: { isSustaining in
                        setSustaining(isSustaining, for: note)
                    }
                )
            }
        }
    }

    private func playOnce(_ note: PianoNote) {
        soundEngine.play(note: note)
        feedback.impactOccurred()
        activeNote = note

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            guard activeNote == note else { return }
            activeNote = nil
        }
    }

    private func setSustaining(_ isSustaining: Bool, for note: PianoNote) {
        if isSustaining {
            if let activeNote, activeNote != note {
                soundEngine.stop(note: activeNote)
            }

            soundEngine.start(note: note)
            feedback.impactOccurred()
            activeNote = note
        } else {
            soundEngine.stop(note: note)
            if activeNote == note { activeNote = nil }
            feedback.prepare()
        }
    }
}

private struct PianoNoteButton: View {
    let note: PianoNote
    let isActive: Bool
    let onTap: () -> Void
    let onSustainChanged: (Bool) -> Void

    private var tint: Color {
        switch note.midi {
        case 42...49:
            return .blue
        case 54...61:
            return .pink
        default:
            return Color(uiColor: .systemGray)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(note.displayName)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.8)

            Text(note.frequency.formatted(.number.precision(.fractionLength(1))) + " " + String(localized: "common.unit.hertz"))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .scaleEffect(isActive ? 0.97 : 1)
        .liquidGlass(tint: tint.opacity(isActive ? 0.30 : 0.14), cornerRadius: 20)
        .overlay {
            PianoKeyTouchSurface(onSustainChanged: onSustainChanged)
                .accessibilityHidden(true)
        }
        .animation(isActive ? nil : .easeOut(duration: 0.12), value: isActive)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("piano.note.name.a11y \(note.displayName)")
        .accessibilityHint("piano.note.playbackHint.a11y")
        .accessibilityAction { onTap() }
    }
}

private struct PianoKeyTouchSurface: UIViewRepresentable {
    let onSustainChanged: (Bool) -> Void

    func makeUIView(context: Context) -> TouchView { TouchView() }

    func updateUIView(_ view: TouchView, context: Context) {
        view.onSustainChanged = onSustainChanged
    }

    static func dismantleUIView(_ view: TouchView, coordinator: ()) {
        view.endSustain()
    }

    final class TouchView: UIView, UIGestureRecognizerDelegate {
        var onSustainChanged: (Bool) -> Void = { _ in }
        private var isSustaining = false
        private var holdOrigin = CGPoint.zero

        override init(frame: CGRect) {
            super.init(frame: frame)
            let hold = UILongPressGestureRecognizer(target: self, action: #selector(handleHold))
            hold.minimumPressDuration = 0
            hold.allowableMovement = 12
            hold.cancelsTouchesInView = false
            hold.delegate = self
            addGestureRecognizer(hold)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        // A sustained key must never prevent the enclosing scroll view from panning.
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            otherGestureRecognizer is UIPanGestureRecognizer
        }

        @objc private func handleHold(_ gesture: UILongPressGestureRecognizer) {
            switch gesture.state {
            case .began:
                holdOrigin = gesture.location(in: window)
                isSustaining = true
                onSustainChanged(true)
            case .changed:
                let position = gesture.location(in: window)
                if hypot(position.x - holdOrigin.x, position.y - holdOrigin.y) > 12 {
                    endSustain()
                }
            case .ended, .cancelled, .failed:
                endSustain()
            default:
                break
            }
        }

        func endSustain() {
            guard isSustaining else { return }
            isSustaining = false
            onSustainChanged(false)
        }
    }
}

private struct LiquidGlassModifier: ViewModifier {
    let tint: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(
                .regular.tint(tint).interactive(),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
        } else {
            content
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(tint.opacity(0.35), lineWidth: 1)
                }
        }
    }
}

private extension View {
    func liquidGlass(tint: Color, cornerRadius: CGFloat) -> some View {
        modifier(LiquidGlassModifier(tint: tint, cornerRadius: cornerRadius))
    }
}

private struct AboutView: View {
    var body: some View {
        Form {
            Section("about.app.title") {
                LabeledContent("about.app.version.label", value: "1.0")
                LabeledContent("about.app.analysisEngine.label", value: "PitcheeCore")
            }
        }
        .navigationTitle("about.screen.title")
    }
}

#if DEBUG
#Preview("Debug - Onboarding") {
    DebugPreviewHost {
        ContentView()
    }
}

#Preview("Mock - Main With History") {
    DebugPreviewHost(withHistory: true, completedOnboarding: true) {
        ContentView()
    }
}

#Preview("Debug - Trends Empty") {
    DebugPreviewHost {
        NavigationStack { TrendsView() }
    }
}

#Preview("Mock - Trends With History") {
    DebugPreviewHost(withHistory: true) {
        NavigationStack { TrendsView() }
    }
}

#Preview("Debug - Piano") {
    NavigationStack { PianoKeysView() }
}

#Preview("Debug - About") {
    NavigationStack { AboutView() }
}
#endif
