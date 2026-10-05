//
//  InsightsDetailViews.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/27.
//

import Charts
import SwiftData
import SwiftUI

struct InsightsRangePicker: View {
    @Binding var selection: InsightsRange

    var body: some View {
        Picker("insights.range.label", selection: $selection) {
            ForEach(InsightsRange.allCases) { range in
                Text(range.title).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("insights.range.label")
    }
}

private struct InsightsPage<Content: View>: View {
    let title: String
    @Binding var range: InsightsRange
    @ViewBuilder let content: () -> Content

    var body: some View {
        List {
            Section {
                InsightsRangePicker(selection: $range)
            }
            content()
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct InsightsCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        Section {
            content()
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct InsightsStat: View {
    let title: LocalizedStringKey
    let value: String
    var tint: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.65)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct InsightsEmptyState: View {
    var title: LocalizedStringKey = "insights.history.empty.title"
    var description: LocalizedStringKey = "insights.history.empty.description"
    var symbol = "waveform"

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: {
            Text(description)
        }
        .padding(.vertical, 24)
    }
}

struct RecordingHistoryView: View {
    @Query(sort: \RecordingAssessment.recordedAt, order: .reverse)
    private var assessments: [RecordingAssessment]
    @Binding var range: InsightsRange

    private var visibleAssessments: [RecordingAssessment] {
        InsightsData.assessments(assessments, in: range)
    }

    private var groupedDays: [Date] {
        Set(visibleAssessments.map { Calendar.current.startOfDay(for: $0.recordedAt) }).sorted(by: >)
    }

    var body: some View {
        InsightsPage(title: String(localized: "insights.history.title"), range: $range) {
            InsightsCard {
                HStack(alignment: .top, spacing: 12) {
                    InsightsStat(title: "insights.summary.analysisCount.title", value: visibleAssessments.count.formatted(), tint: .blue)
                    InsightsStat(title: "insights.history.recordingDays.label", value: groupedDays.count.formatted())
                    InsightsStat(title: "common.metric.speechDuration.title", value: speechDuration)
                }
            }

            if visibleAssessments.isEmpty {
                InsightsEmptyState()
            } else {
                ForEach(groupedDays, id: \.self) { day in
                    Section {
                        InsightsRecordingRows(assessments: visibleAssessments.filter {
                            Calendar.current.isDate($0.recordedAt, inSameDayAs: day)
                        })
                    } header: {
                        Text(day, format: .dateTime.year().month().day().weekday())
                    }
                }
            }
        }
    }

    private var speechDuration: String {
        let seconds = visibleAssessments.reduce(0) { $0 + max(0, $1.speechSeconds) }
        return Duration.seconds(seconds).formatted(.units(allowed: [.hours, .minutes, .seconds], width: .abbreviated, maximumUnitCount: 2))
    }
}

private struct InsightsRecordingRows: View {
    let assessments: [RecordingAssessment]
    var metric: InsightsMetric = .composite
    var includesDate = false
    @AppStorage(AppStorageKey.voicePreference) private var savedVoicePreference = ""

    private var voicePreference: VoicePreference {
        VoicePreference(legacyStoredValue: savedVoicePreference) ?? .undecided
    }

    private var metricTitle: String {
        metric == .composite ? voicePreference.scoreTitleText : metric.title
    }

    var body: some View {
        ForEach(assessments) { assessment in
            NavigationLink {
                RecordingHistoryDetailView(assessment: assessment)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: metric.symbol)
                        .font(.title3)
                        .foregroundStyle(metric.tint)
                        .frame(width: 40, height: 40)
                        .background(metric.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 5) {
                        if includesDate {
                            Text(assessment.recordedAt, format: .dateTime.month().day().hour().minute())
                                .font(.subheadline.weight(.semibold))
                        } else {
                            Text(assessment.recordedAt, format: .dateTime.hour().minute())
                                .font(.headline)
                        }
                        Text(Duration.seconds(max(0, assessment.inputSeconds)), format: .units(allowed: [.minutes, .seconds], width: .abbreviated))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 4)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(metric.formatted(metric.value(in: assessment, preference: voicePreference)))
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(metric.tint)
                        Text(metric == .composite ? metricTitle : metric.unit)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .accessibilityHint("insights.history.record.hint")
        }
    }
}

struct RecordingHistoryDetailView: View {
    let assessment: RecordingAssessment

    var body: some View {
        Group {
            if let result = assessment.result {
                RecordingResultView(result: result, volumeStatistics: nil, saveError: nil, quality: assessment.quality, recordedPreference: assessment.recordedTarget)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            RecordingExportButton(result: result, volumeStatistics: nil)
                                .labelStyle(.iconOnly)
                        }
                    }
            } else {
                ContentUnavailableView {
                    Label("insights.history.unavailable.title", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("insights.history.unavailable.description")
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(Text(assessment.recordedAt, format: .dateTime.month().day().hour().minute()))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InsightsMetricDetailView: View {
    @Query(sort: \RecordingAssessment.recordedAt, order: .reverse)
    private var assessments: [RecordingAssessment]
    let metric: InsightsMetric
    @Binding var range: InsightsRange
    @State private var selectedDate: Date?
    @AppStorage(AppStorageKey.voicePreference) private var savedVoicePreference = ""

    private var voicePreference: VoicePreference {
        VoicePreference(legacyStoredValue: savedVoicePreference) ?? .undecided
    }

    private var metricTitle: String {
        metric == .composite ? voicePreference.scoreTitleText : metric.title
    }

    private struct Sample: Identifiable {
        let assessment: RecordingAssessment
        let value: Double
        var id: UUID { assessment.id }
        var date: Date { Calendar.current.startOfDay(for: assessment.recordedAt) }
    }

    private var dailyAssessments: [RecordingAssessment] {
        InsightsData.dailyBest(InsightsData.assessments(assessments, in: range), preference: voicePreference)
    }

    private var samples: [Sample] {
        dailyAssessments.compactMap { assessment in
            metric.value(in: assessment, preference: voicePreference).map { Sample(assessment: assessment, value: $0) }
        }
    }

    private var selectedSample: Sample? {
        guard let selectedDate else { return nil }
        return samples.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
    }

    var body: some View {
        InsightsPage(title: metricTitle, range: $range) {
            InsightsCard {
                VStack(alignment: .leading, spacing: 18) {
                    Label(metricTitle, systemImage: metric.symbol)
                        .font(.headline)
                        .foregroundStyle(metric.tint)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(selectedDate == nil ? "insights.metric.latest.label" : "insights.metric.selected.label")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            // A missing pitch for the latest day remains missing, as on the home card.
                            Text(metric.formatted(selectedSample?.value ?? dailyAssessments.last.flatMap { metric.value(in: $0, preference: voicePreference) }))
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundStyle(metric.tint)
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                            Text(metric.unit).foregroundStyle(.secondary)
                        }
                        if let date = selectedSample?.assessment.recordedAt ?? dailyAssessments.last?.recordedAt {
                            Text(date, format: .dateTime.year().month().day().hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if !samples.isEmpty {
                        chart
                        Divider()
                        HStack(alignment: .top, spacing: 12) {
                            InsightsStat(title: "insights.metric.average.label", value: metric.formatted(average))
                            InsightsStat(title: "insights.metric.minimum.label", value: metric.formatted(samples.map(\.value).min()))
                            InsightsStat(title: "insights.metric.maximum.label", value: metric.formatted(samples.map(\.value).max()))
                        }
                    }
                }
            }

            InsightsCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("insights.metric.explanation.title").font(.headline)
                    Text(metric.explanation).font(.subheadline).foregroundStyle(.secondary)
                    if metric == .composite, voicePreference != .undecided {
                        Text(voicePreference.scoreDirectionDescription).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Text("insights.metric.dailyBest.description").font(.caption).foregroundStyle(.secondary)
                }
            }

            if samples.isEmpty {
                InsightsEmptyState(title: "insights.metric.empty.title", description: "insights.metric.empty.description", symbol: metric.symbol)
            }
            if !dailyAssessments.isEmpty {
                Section("insights.metric.records.title") {
                    InsightsRecordingRows(assessments: dailyAssessments.reversed(), metric: metric, includesDate: true)
                }
            }
        }
        .onChange(of: range) { selectedDate = nil }
        .onChange(of: savedVoicePreference) { selectedDate = nil }
    }

    private var average: Double? {
        guard !samples.isEmpty else { return nil }
        return samples.reduce(0) { $0 + $1.value } / Double(samples.count)
    }

    private var yDomain: ClosedRange<Double> {
        guard metric == .pitch, let minimum = samples.map(\.value).min(),
              let maximum = samples.map(\.value).max() else { return 0...100 }
        let padding = max(10, (maximum - minimum) * 0.2)
        return max(0, minimum - padding)...(maximum + padding)
    }

    private var dateDomain: ClosedRange<Date> {
        let first = samples.first?.date ?? .now
        let last = samples.last?.date ?? first
        return first.addingTimeInterval(-43_200)...last.addingTimeInterval(43_200)
    }

    private var chart: some View {
        Chart {
            ForEach(samples) { sample in
                if samples.count > 1 {
                    AreaMark(
                        x: .value(String(localized: "insights.chart.date.label"), sample.date),
                        yStart: .value(String(localized: "insights.chart.baseline.label"), yDomain.lowerBound),
                        yEnd: .value(metricTitle, sample.value)
                    )
                    .foregroundStyle(LinearGradient(colors: [metric.tint.opacity(0.20), metric.tint.opacity(0.02)], startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value(String(localized: "insights.chart.date.label"), sample.date), y: .value(metricTitle, sample.value))
                        .foregroundStyle(metric.tint)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                }
                PointMark(x: .value(String(localized: "insights.chart.date.label"), sample.date), y: .value(metricTitle, sample.value))
                    .foregroundStyle(metric.tint)
                    .symbolSize(sample.id == selectedSample?.id ? 80 : 35)
                    .accessibilityLabel(Text(sample.date, format: .dateTime.month().day()))
                    .accessibilityValue(Text(verbatim: "\(metric.formatted(sample.value)) \(metric.unit)"))
            }
            if let selectedSample {
                RuleMark(x: .value(String(localized: "insights.chart.date.label"), selectedSample.date))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
            }
        }
        .chartXScale(domain: dateDomain)
        .chartYScale(domain: yDomain)
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
        .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) }
        .chartXSelection(value: $selectedDate)
        .frame(height: 220)
        .accessibilityLabel(metricTitle)
    }
}

struct InsightsActivityView: View {
    @Query(sort: \RecordingAssessment.recordedAt, order: .reverse)
    private var assessments: [RecordingAssessment]
    @AppStorage(AppStorageKey.openedDateKeys) private var openedDateKeys = ""
    @Binding var range: InsightsRange
    @State private var selectedDay = Calendar.current.startOfDay(for: .now)

    private var calendar: Calendar { .current }
    private var openedDates: Set<Date> {
        InsightsData.openedDates(from: openedDateKeys).filter { range.contains($0) }
    }
    private var visibleAssessments: [RecordingAssessment] {
        InsightsData.assessments(assessments, in: range)
    }
    private var recordingDates: Set<Date> {
        Set(visibleAssessments.map { calendar.startOfDay(for: $0.recordedAt) })
    }
    private var earliestDate: Date {
        range.startDate() ?? min(openedDates.min() ?? .now, visibleAssessments.last?.recordedAt ?? .now)
    }
    private var selectedAssessments: [RecordingAssessment] {
        visibleAssessments.filter { calendar.isDate($0.recordedAt, inSameDayAs: selectedDay) }
    }

    var body: some View {
        InsightsPage(title: String(localized: "insights.activity.title"), range: $range) {
            InsightsCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        InsightsStat(title: "insights.summary.openedDays.title", value: openedDates.count.formatted(), tint: .orange)
                        InsightsStat(title: "insights.history.recordingDays.label", value: recordingDates.count.formatted())
                        InsightsStat(title: "insights.activity.longestStreak.label", value: InsightsData.longestStreak(in: openedDates).formatted())
                    }
                    Text("insights.activity.description")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            InsightsCard {
                VStack(spacing: 18) {
                    InsightsActivityCalendar(
                        selectedDay: $selectedDay,
                        availableDates: availableDates,
                        openedDates: openedDates,
                        recordingDates: recordingDates
                    )
                    HStack(spacing: 18) {
                        Label("insights.activity.opened.label", systemImage: "circle.fill").foregroundStyle(.orange)
                        Label("insights.activity.recorded.label", systemImage: "waveform").foregroundStyle(.blue)
                    }
                    .font(.caption)
                }
            }
            Section {
                Text(calendarStatus(isOpened: openedDates.contains(selectedDay), hasRecordings: recordingDates.contains(selectedDay)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if selectedAssessments.isEmpty {
                    Label("insights.activity.noRecordings.description", systemImage: "waveform")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    InsightsRecordingRows(assessments: selectedAssessments)
                }
            } header: {
                Text(selectedDay, format: .dateTime.year().month().day().weekday())
            }
        }
        .onChange(of: range) {
            if !range.contains(selectedDay) { selectedDay = calendar.startOfDay(for: .now) }
        }
    }

    private var availableDates: DateInterval {
        let today = calendar.startOfDay(for: .now)
        let firstDay = range.startDate()
            ?? calendar.dateInterval(of: .month, for: earliestDate)?.start
            ?? today
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today.addingTimeInterval(86_400)
        return DateInterval(start: min(firstDay, today), end: tomorrow.addingTimeInterval(-1))
    }

    private func calendarStatus(isOpened: Bool, hasRecordings: Bool) -> String {
        var labels: [String] = []
        if isOpened { labels.append(String(localized: "insights.activity.opened.label")) }
        if hasRecordings { labels.append(String(localized: "insights.activity.recorded.label")) }
        return labels.isEmpty ? String(localized: "insights.activity.inactive.label") : labels.joined(separator: ", ")
    }
}

#if DEBUG
private struct InsightsDetailPreview: View {
    let destination: InsightsDestination
    @State private var range: InsightsRange = .all

    var body: some View {
        NavigationStack {
            switch destination {
            case .history: RecordingHistoryView(range: $range)
            case .activity: InsightsActivityView(range: $range)
            case .metric(let metric): InsightsMetricDetailView(metric: metric, range: $range)
            }
        }
        .defaultAppStorage(DebugPreviewDefaults.store)
    }
}

#Preview("Insights - Recording History") {
    if let container = DebugPreviewStore.makeContainer(withHistory: true) {
        InsightsDetailPreview(destination: .history).modelContainer(container)
    }
}

#Preview("Insights - Activity") {
    InsightsDetailPreview(destination: .activity)
        .modelContainer(for: RecordingAssessment.self, inMemory: true)
}

#Preview("Insights - Score Trend") {
    if let container = DebugPreviewStore.makeContainer(withHistory: true) {
        InsightsDetailPreview(destination: .metric(.composite)).modelContainer(container)
    }
}

#Preview("Insights - Naturalness Trend") {
    if let container = DebugPreviewStore.makeContainer(withHistory: true) {
        InsightsDetailPreview(destination: .metric(.naturalness)).modelContainer(container)
    }
}

#Preview("Insights - Pitch Empty") {
    InsightsDetailPreview(destination: .metric(.pitch))
        .modelContainer(for: RecordingAssessment.self, inMemory: true)
}
#endif
