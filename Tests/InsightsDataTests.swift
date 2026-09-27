import Foundation
import SwiftData

@main
enum InsightsDataTests {
    @MainActor
    static func main() throws {
        var checks = 0
        func check(_ condition: @autoclosure () -> Bool, _ message: String) {
            checks += 1
            precondition(condition(), message)
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        calendar.firstWeekday = 2
        func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
        }
        let now = date(2026, 9, 27, 12)
        for (range, count) in [(InsightsRange.sevenDays, 7), (.thirtyDays, 30), (.ninetyDays, 90)] {
            let start = range.startDate(relativeTo: now, calendar: calendar)!
            check(calendar.dateComponents([.day], from: start, to: calendar.startOfDay(for: now)).day == count - 1,
                  "Each range must include exactly its stated number of calendar days")
            check(range.contains(start, relativeTo: now, calendar: calendar), "Include the start boundary")
            check(!range.contains(start.addingTimeInterval(-1), relativeTo: now, calendar: calendar), "Exclude the preceding day")
            check(range.contains(date(2026, 9, 27, 23), relativeTo: now, calendar: calendar), "Include all of today")
            check(!range.contains(date(2026, 9, 28), relativeTo: now, calendar: calendar), "Exclude future days")
        }
        check(InsightsRange.all.contains(date(2000, 1, 1), relativeTo: now, calendar: calendar), "All includes older history")
        check(!InsightsRange.all.contains(date(2026, 9, 28), relativeTo: now, calendar: calendar), "All still excludes future days")
        check(InsightsRange.sevenDays.startDate(relativeTo: date(2026, 3, 10), calendar: calendar) == date(2026, 3, 4),
              "Spring daylight-saving ranges use calendar days")
        check(InsightsRange.sevenDays.startDate(relativeTo: date(2026, 11, 3), calendar: calendar) == date(2026, 10, 28),
              "Fall daylight-saving ranges use calendar days")

        let opened = InsightsData.openedDates(from: "2026-9-27,2026-09-27,2024-2-29,2026-2-29,2026-13-1,2026--2-3,garbage", calendar: calendar)
        check(opened == Set([date(2026, 9, 27), date(2024, 2, 29)]), "Deduplicate valid dates and reject normalized invalid dates")
        check(InsightsData.openedDates(from: "", calendar: calendar).isEmpty, "Missing usage history stays empty")
        check(InsightsData.longestStreak(in: [], calendar: calendar) == 0, "An empty calendar has no streak")
        check(InsightsData.longestStreak(in: Set([date(2026, 3, 7), date(2026, 3, 8), date(2026, 3, 9), date(2026, 3, 11)]), calendar: calendar) == 3,
              "Consecutive days survive daylight-saving transitions")
        check(InsightsData.longestStreak(in: Set([date(2025, 12, 31), date(2026, 1, 1)]), calendar: calendar) == 2,
              "Streaks continue across year boundaries")

        let february = InsightsData.monthCells(containing: date(2024, 2, 15), calendar: calendar)
        check(february.prefix(3).allSatisfy { $0 == nil }, "Month grid respects Monday as the first weekday")
        check(february.compactMap { $0 }.count == 29, "Leap month contains every date exactly once")
        check(february.last! == date(2024, 2, 29), "Month grid ends on the correct day")
        var sundayCalendar = calendar
        sundayCalendar.firstWeekday = 1
        check(InsightsData.monthCells(containing: date(2026, 2, 1), calendar: sundayCalendar).first! == date(2026, 2, 1),
              "Months starting on the first weekday need no padding")

        func assessment(_ recordedAt: Date, score: Double, pitch: Double? = 175) throws -> RecordingAssessment {
            let result = PitcheeAnalysisResult(
                schemaVersion: 2, modelVersion: "insights-tests",
                audio: .init(sourceSampleRate: 16_000, sourceChannels: 1, inputSeconds: 12, analyzedSeconds: 12),
                vad: .init(segmentCount: 0, speechSeconds: 10, sileroSegmentCount: 0, discardedBreathLikeCount: 0, trimmedSegmentCount: 0, segments: []),
                f0: .init(windowSeconds: 0.5, meanHz: pitch, standardDeviationHz: nil, voicedFrameCount: 0, voicedWindowCount: 0, windows: []),
                vfp: .init(vfpStandardScore: 65, windowCount: 0, windowDurationSeconds: 1, windows: []),
                naturalness: .init(score: 70, windowCount: 0, windowDurationSeconds: 1, windows: []),
                composite: .init(baseScore: score, finalScore: score, cap: nil, rule: "continuous", limited: false, boosted: false)
            )
            return try RecordingAssessment(recordedAt: recordedAt, result: result)
        }
        let first = try assessment(date(2026, 9, 21, 8), score: 90)
        let lower = try assessment(date(2026, 9, 21, 9), score: 60)
        let tiedLater = try assessment(date(2026, 9, 21, 10), score: 90)
        let latest = try assessment(date(2026, 9, 27, 11), score: 80, pitch: nil)
        let older = try assessment(date(2026, 9, 20), score: 99)
        let future = try assessment(date(2026, 9, 28), score: 99)
        let all = [latest, lower, older, tiedLater, first, future]
        let visible = InsightsData.assessments(all, in: .sevenDays, relativeTo: now, calendar: calendar)
        check(visible.count == 4, "History includes every recording within the selected period")
        let best = InsightsData.dailyBest(visible, calendar: calendar)
        check(best.map(\.id) == [tiedLater.id, latest.id], "Daily results choose the highest score, break ties by recency, and sort by day")
        check(InsightsData.dailyBest([], calendar: calendar).isEmpty, "Empty histories have no daily results")
        check(InsightsMetric.composite.value(in: latest) == 80, "Read the saved composite score")
        check(InsightsMetric.naturalness.value(in: latest) == 70, "Read the saved naturalness score")
        check(InsightsMetric.pitch.value(in: first) == 175, "Read a valid saved pitch")
        check(InsightsMetric.pitch.value(in: latest) == nil, "Missing pitch stays missing rather than becoming zero")
        latest.meanPitchHz = -1
        check(InsightsMetric.pitch.value(in: latest) == nil, "Invalid negative pitch is excluded")
        latest.meanPitchHz = .infinity
        check(InsightsMetric.pitch.value(in: latest) == nil, "Non-finite pitch is excluded")
        latest.meanPitchHz = nil

        let container = try ModelContainer(for: RecordingAssessment.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        container.mainContext.insert(first)
        try container.mainContext.save()
        let saved = try container.mainContext.fetch(FetchDescriptor<RecordingAssessment>())
        check(saved.count == 1, "Saved analyses can be queried by the history page")
        check(saved.first?.result?.composite.finalScore == 90, "Saved result payload reconstructs full analysis details")
        first.resultPayload = Data("invalid".utf8)
        check(first.result == nil, "Unreadable payloads use the detail page error state without crashing")
        print("Insights: \(checks) checks passed")
    }
}
