import Foundation

enum InsightsRange: String, CaseIterable, Identifiable {
    case sevenDays, thirtyDays, ninetyDays, all

    var id: Self { self }

    var title: String {
        switch self {
        case .sevenDays: String(localized: "insights.range.sevenDays")
        case .thirtyDays: String(localized: "insights.range.thirtyDays")
        case .ninetyDays: String(localized: "insights.range.ninetyDays")
        case .all: String(localized: "insights.range.all")
        }
    }

    func startDate(relativeTo date: Date = .now, calendar: Calendar = .current) -> Date? {
        let days: Int
        switch self {
        case .sevenDays: days = 7
        case .thirtyDays: days = 30
        case .ninetyDays: days = 90
        case .all: return nil
        }
        // Today is one of the selected days, including across daylight-saving changes.
        return calendar.date(byAdding: .day, value: 1 - days, to: calendar.startOfDay(for: date))
    }

    func contains(_ date: Date, relativeTo now: Date = .now, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        return day <= calendar.startOfDay(for: now)
            && startDate(relativeTo: now, calendar: calendar).map { day >= $0 } != false
    }
}

enum InsightsMetric: String, CaseIterable, Identifiable {
    case composite, naturalness, pitch

    var id: Self { self }

    var title: String {
        switch self {
        case .composite: String(localized: "common.metric.compositeScore.title")
        case .naturalness: String(localized: "common.metric.naturalness.title")
        case .pitch: String(localized: "common.metric.meanPitch.title")
        }
    }

    var explanation: String {
        switch self {
        case .composite: String(localized: "insights.metric.compositeScore.description")
        case .naturalness: String(localized: "insights.metric.naturalness.description")
        case .pitch: String(localized: "insights.metric.meanPitch.description")
        }
    }

    var symbol: String {
        switch self {
        case .composite: "chart.line.uptrend.xyaxis"
        case .naturalness: "waveform.path.ecg"
        case .pitch: "tuningfork"
        }
    }

    var unit: String {
        self == .pitch
            ? String(localized: "common.unit.hertz")
            : String(localized: "common.unit.pointsOutOf100")
    }

    func value(in assessment: RecordingAssessment) -> Double? {
        let value: Double?
        switch self {
        case .composite: value = assessment.finalScore
        case .naturalness: value = assessment.naturalnessScore
        case .pitch: value = assessment.meanPitchHz
        }
        guard let value, value.isFinite, self != .pitch || value > 0 else { return nil }
        return value
    }

    func formatted(_ value: Double?) -> String {
        guard let value, value.isFinite else { return String(localized: "common.placeholder.noValue") }
        return value.formatted(.number.precision(.fractionLength(self == .pitch ? 1 : 0)))
    }
}

enum InsightsDestination: Hashable {
    case history, activity, metric(InsightsMetric)
}

enum InsightsData {
    static func assessments(
        _ assessments: [RecordingAssessment],
        in range: InsightsRange,
        relativeTo now: Date = .now,
        calendar: Calendar = .current
    ) -> [RecordingAssessment] {
        assessments.filter { range.contains($0.recordedAt, relativeTo: now, calendar: calendar) }
    }

    /// Every metric uses the same daily representative as the home dashboard.
    static func dailyBest(
        _ assessments: [RecordingAssessment], calendar: Calendar = .current
    ) -> [RecordingAssessment] {
        Dictionary(grouping: assessments) { calendar.startOfDay(for: $0.recordedAt) }
            .values.compactMap { records in
                records.max { lhs, rhs in
                    if lhs.finalScore == rhs.finalScore { return lhs.recordedAt < rhs.recordedAt }
                    return lhs.finalScore < rhs.finalScore
                }
            }
            .sorted { $0.recordedAt < $1.recordedAt }
    }

    static func openedDates(from storedKeys: String, calendar: Calendar = .current) -> Set<Date> {
        Set(storedKeys.split(separator: ",").compactMap { key -> Date? in
            let parts = key.split(separator: "-", omittingEmptySubsequences: false)
            guard parts.count == 3,
                  let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]),
                  let date = calendar.date(from: DateComponents(year: year, month: month, day: day))
            else { return nil }
            let actual = calendar.dateComponents([.year, .month, .day], from: date)
            // Calendar.date normalizes invalid dates; persisted keys must match exactly.
            guard actual.year == year, actual.month == month, actual.day == day else { return nil }
            return calendar.startOfDay(for: date)
        })
    }

    static func longestStreak(in dates: Set<Date>, calendar: Calendar = .current) -> Int {
        var previous: Date?
        var current = 0
        var longest = 0
        for date in dates.sorted() {
            if let previous, calendar.date(byAdding: .day, value: 1, to: previous) == date {
                current += 1
            } else {
                current = 1
            }
            longest = max(longest, current)
            previous = date
        }
        return longest
    }

    static func monthCells(containing date: Date, calendar: Calendar = .current) -> [Date?] {
        guard let month = calendar.dateInterval(of: .month, for: date),
              let days = calendar.range(of: .day, in: .month, for: date) else { return [] }
        let offset = (calendar.component(.weekday, from: month.start) - calendar.firstWeekday + 7) % 7
        let dates = days.map { calendar.date(byAdding: .day, value: $0 - 1, to: month.start) }
        return Array(repeating: nil, count: offset) + dates
    }
}
