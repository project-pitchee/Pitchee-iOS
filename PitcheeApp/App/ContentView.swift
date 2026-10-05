//
//  ContentView.swift
//  Pitchee
//
//  Created by Lvy Zhan on 2026/6/12.
//

import SwiftData
import SwiftUI
import UIKit
import Charts

struct ContentView: View {
    @AppStorage(AppStorageKey.onboardingCompletedVersion) private var completedOnboardingVersion = 0
    @AppStorage(AppStorageKey.voicePreference) private var savedVoicePreference = ""
    @AppStorage(AppStorageKey.customThemeColor) private var customThemeColor = ""

    private var themeColor: Color {
        AppTheme.color(
            for: VoicePreference(legacyStoredValue: savedVoicePreference) ?? .undecided,
            customHex: customThemeColor
        )
    }

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
        .tint(themeColor)
    }
}

private struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var recordingModel = AnalysisViewModel()
    @State private var selectedTab: AppTab = .trends
    @State private var showsRecordingAnalysis = false
    @State private var monitorAccessoryState = MonitorAccessoryState()
    @State private var practicePath: [MonitorKind] = []

    init() {
        #if DEBUG
        // Lets the isolated review simulator open this page without altering saved preferences.
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-practice-hub-preview")
            || arguments.contains("-monitor-review-pitch")
            || arguments.contains("-monitor-review-spectrum") {
            _selectedTab = State(initialValue: .practice)
        }
        if arguments.contains("-monitor-review-pitch") {
            _practicePath = State(initialValue: [.pitch])
        } else if arguments.contains("-monitor-review-spectrum") {
            _practicePath = State(initialValue: [.spectrum])
        }
        #endif
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TrendsView()
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

            NavigationStack(path: $practicePath) {
                PracticeHubView()
                    .navigationDestination(for: MonitorKind.self) { kind in
                        switch kind {
                        case .pitch: PitchMonitorView()
                        case .spectrum: SpectrumMonitorView()
                        }
                    }
            }
            .tabItem {
                Label(AppTab.practice.title, systemImage: AppTab.practice.systemImage)
            }
            .tag(AppTab.practice)

            NavigationStack {
                PianoKeysView()
            }
            .tabItem {
                Label(AppTab.pianoKeys.title, systemImage: AppTab.pianoKeys.systemImage)
            }
            .tag(AppTab.pianoKeys)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(AppTab.about.title, systemImage: AppTab.about.systemImage)
            }
            .tag(AppTab.about)
        }
        .modifier(TabBarAccessory(isVisible: showsRecordingAccessory || activeMonitorModel != nil) {
            if let model = activeMonitorModel {
                MonitorAccessoryContent(model: model)
            } else {
                RecordingAccessoryContent(viewModel: recordingModel, action: recordingAction)
            }
        })
        .environment(\.monitorAccessoryState, monitorAccessoryState)
        .onChange(of: selectedTab) { _, tab in
            if tab != .practice { monitorAccessoryState.leavePractice() }
        }
    }

    private var showsRecordingAccessory: Bool {
        (selectedTab == .recording && !showsRecordingAnalysis)
            || recordingModel.isRecording || recordingModel.isRequestingPermission
    }

    private var activeMonitorModel: MonitorViewModel? {
        guard selectedTab == .practice,
              !recordingModel.isRecording, !recordingModel.isRequestingPermission else { return nil }
        return monitorAccessoryState.model
    }

    private func recordingAction() {
        if recordingModel.needsAnalysisScreen {
            selectedTab = .recording
            showsRecordingAnalysis = true
            return
        }
        recordingModel.primaryButtonTapped(modelContext: modelContext)
        if recordingModel.needsAnalysisScreen {
            selectedTab = .recording
            showsRecordingAnalysis = true
        }
    }
}

private enum AppTab: Hashable {
    case trends
    case recording
    case practice
    case pianoKeys
    case about

    var title: LocalizedStringKey {
        switch self {
        case .trends:
            "insights.screen.title"
        case .recording:
            "recording.screen.title"
        case .practice:
            "practice.hub.tab"
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
        case .practice:
            "figure.mind.and.body"
        case .pianoKeys:
            "pianokeys"
        case .about:
            "info.circle"
        }
    }
}

private struct TrendsView: View {
    private struct TrendPoint: Identifiable {
        let id: UUID
        let date: Date
        let value: Double
        let position: Double
    }

    @Query(sort: \RecordingAssessment.recordedAt, order: .reverse)
    private var assessments: [RecordingAssessment]
    @AppStorage(AppStorageKey.openedDateKeys) private var openedDateKeys = ""
    @State private var selectedRange: InsightsRange = .sevenDays
    @AppStorage(AppStorageKey.voicePreference) private var savedVoicePreference = ""

    private var voicePreference: VoicePreference {
        VoicePreference(legacyStoredValue: savedVoicePreference) ?? .undecided
    }

    /// Placeholder for a metric that has no value yet. Kept in one place so
    /// cards use the same empty state as the rest of the app.
    private static let noValue = String(localized: "common.placeholder.noValue")

    private var visibleAssessments: [RecordingAssessment] {
        InsightsData.assessments(assessments, in: selectedRange)
    }

    private var latestAssessment: RecordingAssessment? {
        dailyBestAssessments.last
    }

    private var averages: RecordingAssessmentAverages {
        RecordingAssessmentAverages(assessments: Array(dailyBestAssessments.dropLast()), preference: voicePreference)
    }

    /// Keep one representative result per day so repeated recordings do not
    /// make the trend chart look denser than the activity really was. The
    /// highest overall score represents that day's best result.
    private var dailyBestAssessments: [RecordingAssessment] {
        InsightsData.dailyBest(visibleAssessments, preference: voicePreference)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                InsightsRangePicker(selection: $selectedRange)
                summaryCards
                NavigationLink(value: InsightsDestination.metric(.composite)) {
                    overallScoreCard
                }
                .buttonStyle(.plain)
                .accessibilityHint("insights.metric.openDetails.hint")
                metricCards

                if visibleAssessments.isEmpty {
                    emptyState
                }
            }
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(Text(verbatim: "Pitchee"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear(perform: recordTodayAsOpened)
        .navigationDestination(for: InsightsDestination.self) { destination in
            switch destination {
            case .history:
                RecordingHistoryView(range: $selectedRange)
            case .activity:
                InsightsActivityView(range: $selectedRange)
            case .metric(let metric):
                InsightsMetricDetailView(metric: metric, range: $selectedRange)
            }
        }
    }

    private var summaryCards: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            NavigationLink(value: InsightsDestination.history) {
                summaryCard(
                    title: "insights.summary.analysisCount.title",
                    value: visibleAssessments.count.formatted(),
                    symbol: "waveform",
                    tint: .blue
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("insights.history.openDetails.hint")
            NavigationLink(value: InsightsDestination.activity) {
                summaryCard(
                    title: "insights.summary.openedDays.title",
                    value: openedDays.formatted(),
                    symbol: "calendar",
                    tint: .orange
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("insights.activity.openDetails.hint")
        }
    }

    private func summaryCard(
        title: LocalizedStringKey,
        value: String,
        symbol: String,
        tint: Color
    ) -> some View {
        dashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: symbol)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(tint)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }

                Text(value)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var overallScoreCard: some View {
        dashboardCard(minHeight: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(voicePreference.scoreTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(latestAssessment.map { scoreText($0.finalScore(for: voicePreference)) } ?? Self.noValue)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(latestAssessment == nil ? Color.secondary : Color.blue)
                        .minimumScaleFactor(0.7)

                    scoreChangeText
                }

                if let baseline = averages.finalScore {
                    Text("insights.metric.baselineAverage.caption \(scoreText(baseline))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("insights.metric.compositeScore.caption")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                scoreChart
            }
        }
    }

    @ViewBuilder
    private var scoreChart: some View {
        trendChart(
            points: scorePoints,
            tint: .purple,
            yDomain: 0...100,
            height: 126,
            showsXAxis: true
        )
        .accessibilityLabel(Text(voicePreference.scoreTitle))
        .accessibilityValue(chartAccessibilityValue)
    }

    @ViewBuilder
    private var scoreChangeText: some View {
        if let current = latestAssessment?.finalScore(for: voicePreference), let baseline = averages.finalScore, baseline != 0 {
            let change = (current - baseline) / abs(baseline) * 100
            // A tiny difference is normal rounding noise. Do not present it
            // as a direction of travel (for example, “↓ 0%”).
            if abs(change) >= 0.5 {
                let symbol = change > 0 ? "↑" : "↓"
                Text(verbatim: "\(symbol) \(abs(change).formatted(.number.precision(.fractionLength(0))))%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(change > 0 ? Color.green : Color.red)
            }
        }
    }

    private var scorePoints: [TrendPoint] {
        dailyBestAssessments.enumerated().map { index, assessment in
            TrendPoint(id: assessment.id, date: chartDate(for: assessment), value: assessment.finalScore(for: voicePreference), position: Double(index))
        }
    }

    private var chartAccessibilityValue: Text {
        guard let first = scorePoints.first, let last = scorePoints.last else {
            return Text(verbatim: "")
        }
        return Text("insights.chart.scoreTrend.a11y \(scoreText(first.value)) \(scoreText(last.value))")
    }

    @ViewBuilder
    private func trendChart(
        points: [TrendPoint],
        tint: Color,
        yDomain: ClosedRange<Double>,
        height: CGFloat,
        showsXAxis: Bool
    ) -> some View {
        if points.isEmpty {
            EmptyView()
        } else if showsXAxis {
            baseTrendChart(points: points, tint: tint, yDomain: yDomain, height: height)
                .chartXAxis {
                    AxisMarks(values: points.map(\.position)) { value in
                        AxisGridLine().foregroundStyle(.clear)
                        AxisTick().foregroundStyle(.clear)
                        AxisValueLabel(anchor: .top) {
                            if let position = value.as(Double.self),
                               let point = points.first(where: { $0.position == position }) {
                                Text(point.date, format: .dateTime.month(.defaultDigits).day(.defaultDigits))
                            }
                        }
                    }
                }
        } else {
            baseTrendChart(points: points, tint: tint, yDomain: yDomain, height: height)
                .chartXAxis(.hidden)
        }
    }

    private func baseTrendChart(
        points: [TrendPoint],
        tint: Color,
        yDomain: ClosedRange<Double>,
        height: CGFloat
    ) -> some View {
        Chart(points) { point in
            if points.count > 1 {
                AreaMark(
                    x: .value(String(localized: "insights.chart.date.label"), point.position),
                    yStart: .value(String(localized: "insights.chart.baseline.label"), yDomain.lowerBound),
                    yEnd: .value(String(localized: "insights.chart.value.label"), point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [tint.opacity(0.24), tint.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }

            LineMark(
                x: .value(String(localized: "insights.chart.date.label"), point.position),
                y: .value(String(localized: "insights.chart.value.label"), point.value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(tint)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

            PointMark(
                x: .value(String(localized: "insights.chart.date.label"), point.position),
                y: .value(String(localized: "insights.chart.value.label"), point.value)
            )
            .foregroundStyle(tint)
            .symbolSize(28)
        }
        .chartXScale(domain: xDomain(for: points))
        .chartYScale(
            domain: yDomain,
            range: .plotDimension(startPadding: 4, endPadding: 6)
        )
        .chartYAxis(.hidden)
        .chartPlotStyle { plot in
            plot
                .frame(height: height)
                .clipped()
        }
    }

    private var metricCards: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            NavigationLink(value: InsightsDestination.metric(.naturalness)) {
                metricCard(
                    title: "common.metric.naturalness.title",
                    value: latestAssessment.map { scoreText($0.naturalnessScore) } ?? Self.noValue,
                    current: latestAssessment?.naturalnessScore,
                    baseline: averages.naturalnessScore,
                    baselineText: averages.naturalnessScore.map(scoreText),
                    symbol: "waveform.path.ecg",
                    tint: .purple,
                    points: naturalnessPoints,
                    yDomain: 0...100
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("insights.metric.openDetails.hint")
            NavigationLink(value: InsightsDestination.metric(.pitch)) {
                metricCard(
                    title: "common.metric.meanPitch.title",
                    value: latestAssessment?.meanPitchHz.map(decimalText) ?? Self.noValue,
                    current: latestAssessment?.meanPitchHz,
                    baseline: averages.meanPitchHz,
                    baselineText: averages.meanPitchHz.map(decimalText),
                    symbol: "tuningfork",
                    tint: .teal,
                    points: pitchPoints,
                    yDomain: pitchChartDomain
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("insights.metric.openDetails.hint")
        }
    }

    private var naturalnessPoints: [TrendPoint] {
        dailyBestAssessments.enumerated().map { index, assessment in
            TrendPoint(id: assessment.id, date: chartDate(for: assessment), value: assessment.naturalnessScore, position: Double(index))
        }
    }

    private var pitchPoints: [TrendPoint] {
        dailyBestAssessments
            .compactMap { assessment -> (RecordingAssessment, Double)? in
                guard let pitch = assessment.meanPitchHz else { return nil }
                return (assessment, pitch)
            }
            .enumerated()
            .map { index, item in
                TrendPoint(
                    id: item.0.id,
                    date: chartDate(for: item.0),
                    value: item.1,
                    position: Double(index)
                )
            }
    }

    private func xDomain(for points: [TrendPoint]) -> ClosedRange<Double> {
        guard let first = points.first?.position, let last = points.last?.position else {
            return 0...1
        }
        if first == last { return (first - 0.5)...(last + 0.5) }
        return (first - 0.15)...(last + 0.15)
    }

    private func chartDate(for assessment: RecordingAssessment) -> Date {
        Calendar.current.startOfDay(for: assessment.recordedAt)
    }

    private var pitchChartDomain: ClosedRange<Double> {
        let values = pitchPoints.map(\.value)
        guard let minimum = values.min(), let maximum = values.max() else {
            return 0...1
        }
        let padding = max((maximum - minimum) * 0.2, 1)
        return max(0, minimum - padding)...(maximum + padding)
    }

    private func metricCard(
        title: LocalizedStringKey,
        value: String,
        current: Double?,
        baseline: Double?,
        baselineText: String?,
        symbol: String,
        tint: Color,
        points: [TrendPoint],
        yDomain: ClosedRange<Double>
    ) -> some View {
        dashboardCard(minHeight: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: symbol)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(tint)
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }

                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(value == Self.noValue ? Color.secondary : tint)
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)

                if let baseline {
                    VStack(alignment: .leading, spacing: 3) {
                        trendText(current: current, baseline: baseline)
                            .font(.caption.weight(.semibold))
                        if let baselineText {
                            Text("insights.metric.baselineAverage.caption \(baselineText)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } else {
                    Text("insights.metric.baselineAverage.caption \(Self.noValue)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                trendChart(
                    points: points,
                    tint: tint,
                    yDomain: yDomain,
                    height: 54,
                    showsXAxis: false
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("insights.history.empty.description")
                .font(.subheadline)
                .foregroundStyle(.secondary)

        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func dashboardCard<Content: View>(
        minHeight: CGFloat = 138,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var openedDays: Int {
        InsightsData.openedDates(from: openedDateKeys).filter { selectedRange.contains($0) }.count
    }

    private func scoreText(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }

    private func decimalText(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }

    @ViewBuilder
    private func trendText(current: Double?, baseline: Double?) -> some View {
        if let current, let baseline, baseline != 0 {
            let change = (current - baseline) / abs(baseline) * 100
            if abs(change) >= 0.5 {
                let symbol = change > 0 ? "↑" : "↓"
                Text(verbatim: "\(symbol) \(abs(change).formatted(.number.precision(.fractionLength(0))))%")
                    .foregroundStyle(change > 0 ? Color.green : Color.red)
            }
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
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            feedback.prepare()
            await soundEngine.prepare()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                soundEngine.stopAll()
                activeNote = nil
            }
        }
        .onDisappear {
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

#if DEBUG
#Preview("Debug - Onboarding") {
    ContentView()
        .defaultAppStorage(DebugPreviewDefaults.store)
}

#Preview("Debug - Trends Empty") {
    NavigationStack { TrendsView() }
        .modelContainer(for: RecordingAssessment.self, inMemory: true)
        .defaultAppStorage(DebugPreviewDefaults.store)
}

#Preview("Mock - Trends With History") {
    if let container = DebugPreviewStore.makeContainer(withHistory: true) {
        NavigationStack { TrendsView() }
            .modelContainer(container)
            .defaultAppStorage(DebugPreviewDefaults.store)
    } else {
        Text(verbatim: "Unable to create the preview store.")
    }
}

#Preview("Debug - Piano") {
    NavigationStack { PianoKeysView() }
}

#Preview("Debug - About") {
    NavigationStack { SettingsView() }
}
#endif
