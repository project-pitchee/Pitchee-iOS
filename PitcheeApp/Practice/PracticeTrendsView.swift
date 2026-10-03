//
//  PracticeTrendsView.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/30.
//

import Charts
import SwiftUI

struct PracticeTrendsView: View {
    @Environment(\.colorSchemeContrast) private var contrast
    let assessments: [RecordingAssessment]
    var initialMetric: InsightsMetric = .pitch
    @State private var selectedCohort: PracticeCohort?
    @State private var selectedMetric: InsightsMetric = .pitch
    @State private var showsBest = false
    @AppStorage(AppStorageKey.voicePreference) private var savedVoicePreference = ""

    private var cohorts: [PracticeCohort] { InsightsData.cohorts(assessments) }
    private var cohort: PracticeCohort? {
        if let selectedCohort, cohorts.contains(selectedCohort) { return selectedCohort }
        let target = VoicePreference(legacyStoredValue: savedVoicePreference) ?? .undecided
        return cohorts.first { $0.target == target } ?? cohorts.first
    }
    private var metric: InsightsMetric {
        selectedMetric == .composite && cohort?.target == .undecided ? .pitch : selectedMetric
    }
    private var summaries: [DailyPracticeSummary] {
        guard let cohort else { return [] }
        return InsightsData.dailySummary(assessments, cohort: cohort, metric: metric)
    }
    private func displayed(_ day: DailyPracticeSummary) -> Double { showsBest && metric.hasBestView ? day.maximum : day.median }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("practice.trend.title").font(.title2.bold())
            Text("practice.trend.scope").font(.footnote).foregroundStyle(.secondary)
            if let cohort {
                Picker("practice.trend.group", selection: Binding(
                    get: { cohort }, set: { selectedCohort = $0 }
                )) {
                    ForEach(Array(cohorts.enumerated()), id: \.element) { index, item in
                        Text("\(index + 1). \(item.kind.title) · \(targetTitle(item.target))").tag(item)
                    }
                }
                .pickerStyle(.menu)
                Text(cohort.passage).font(.footnote).foregroundStyle(.secondary)
                Picker("practice.trend.metric", selection: $selectedMetric) {
                    Text(InsightsMetric.pitch.title).tag(InsightsMetric.pitch)
                    Text(InsightsMetric.variation.title).tag(InsightsMetric.variation)
                    Text(InsightsMetric.naturalness.title).tag(InsightsMetric.naturalness)
                    if cohort.target != .undecided {
                        Text(cohort.target.scoreTitle).tag(InsightsMetric.composite)
                    }
                }
                .pickerStyle(.menu)
                if metric.hasBestView {
                    Picker("practice.trend.statistic", selection: $showsBest) {
                        Text("practice.trend.median").tag(false)
                        Text("practice.trend.best").tag(true)
                    }
                    .modifier(AccessiblePickerStyle())
                }
                if let latest = summaries.last {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(!metric.hasBestView || !showsBest ? "practice.trend.median" : "practice.trend.best").font(.headline)
                        Text("\(metric.formatted(displayed(latest))) \(metric.unit)")
                            .font(.system(.largeTitle, design: .rounded).bold())
                        dayDescription(latest)
                    }
                    chart
                    DisclosureGroup("practice.trend.dailyValues") {
                        ForEach(summaries.reversed()) { day in
                            VStack(alignment: .leading, spacing: 5) {
                                Text("\(metric.formatted(displayed(day))) \(metric.unit)").font(.headline)
                                dayDescription(day)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 6)
                            .accessibilityElement(children: .combine)
                        }
                    }
                } else {
                    Text("practice.trend.empty").font(.subheadline).foregroundStyle(.secondary)
                }
                if showsBest && metric.hasBestView {
                    Text("practice.trend.bestScope").font(.caption).foregroundStyle(.secondary)
                }
                DisclosureGroup("practice.trend.methods") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("practice.history.version \(cohort.scoringVersion)")
                        Text("practice.trend.model \(cohort.modelVersion)")
                        Text("practice.trend.medianScope")
                    }.font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Text("practice.trend.empty").font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        .onAppear { selectedMetric = initialMetric }
        .onChange(of: metric) { _, metric in if !metric.hasBestView { showsBest = false } }
        .onChange(of: cohort) { _, cohort in
            if cohort?.target == .undecided && selectedMetric == .composite { selectedMetric = .pitch }
        }
    }

    private func targetTitle(_ target: VoicePreference) -> String {
        switch target {
        case .feminine: String(localized: "voiceProfile.option.feminine.title")
        case .masculine: String(localized: "voiceProfile.option.masculine.title")
        case .undecided: String(localized: "voiceProfile.option.undecided.title")
        }
    }

    private func dayDescription(_ day: DailyPracticeSummary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(day.date, format: .dateTime.year().month().day())
            Text("practice.trend.range \(metric.formatted(day.minimum)) \(metric.formatted(day.maximum)) \(day.count)")
        }.font(.caption).foregroundStyle(.secondary)
    }

    private var chart: some View {
        Chart(summaries) { day in
            RuleMark(x: .value(String(localized: "insights.chart.date.label"), day.date), yStart: .value(String(localized: "insights.metric.minimum.label"), day.minimum), yEnd: .value(String(localized: "insights.metric.maximum.label"), day.maximum))
                .foregroundStyle(Color.pitcheeAccent.opacity(contrast == .increased ? 0.75 : 0.35)).lineStyle(StrokeStyle(lineWidth: 6))
            LineMark(x: .value(String(localized: "insights.chart.date.label"), day.date), y: .value(metric.title, displayed(day)))
                .foregroundStyle(Color.pitcheeAccent)
            PointMark(x: .value(String(localized: "insights.chart.date.label"), day.date), y: .value(metric.title, displayed(day)))
                .foregroundStyle(Color.pitcheeAccent)
                .accessibilityLabel(Text(day.date, format: .dateTime.month().day()))
                .accessibilityValue(
                    Text(verbatim: "\(metric.formatted(displayed(day))) \(metric.unit), ")
                    + Text("practice.trend.range \(metric.formatted(day.minimum)) \(metric.formatted(day.maximum)) \(day.count)")
                )
        }
        .chartXScale(domain: dateDomain)
        .chartYScale(domain: valueDomain)
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
        .frame(height: 190)
        .accessibilityLabel("practice.trend.title")
    }

    private var dateDomain: ClosedRange<Date> {
        let first = summaries.first?.date ?? .now
        let last = summaries.last?.date ?? first
        return first.addingTimeInterval(-43_200)...last.addingTimeInterval(43_200)
    }
    private var valueDomain: ClosedRange<Double> {
        guard !metric.hasBestView else { return 0...100 }
        let low = summaries.map(\.minimum).min() ?? 0
        let high = summaries.map(\.maximum).max() ?? 1
        let margin = max(10, (high - low) * 0.1)
        return max(0, low - margin)...(high + margin)
    }
}
