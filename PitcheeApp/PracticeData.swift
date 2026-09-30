//
//  PracticeData.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/30.
//

import Foundation

nonisolated enum PracticeKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case pitchObservation, pitchStability, dailyReading
    var id: String { rawValue }
    var title: String { String(localized: String.LocalizationValue("practice.kind.\(rawValue).title")) }
    var instruction: String { String(localized: String.LocalizationValue("practice.kind.\(rawValue).instruction")) }
    var metric: PracticeMetric {
        switch self {
        case .pitchObservation: .pitch
        case .pitchStability: .variation
        case .dailyReading: .speech
        }
    }
}

/// Frozen before microphone permission, including the rendered passage. A locale
/// or settings change between A and B must not change the comparison task.
nonisolated struct PracticeContext: Codable, Equatable, Sendable {
    let sessionID: UUID
    let kind: PracticeKind
    let target: VoicePreference
    let promptID: String
    let passage: String
    let scoringVersion: String

    init(kind: PracticeKind, target: VoicePreference) {
        sessionID = UUID()
        self.kind = kind
        self.target = target
        promptID = "short-reading-v1"
        passage = String(localized: "practice.passage.v1")
        scoringVersion = VoiceDirectionScore.rulesVersion
    }
}

nonisolated enum PracticeMetric: String, CaseIterable, Identifiable {
    case pitch, variation, speech
    var id: String { rawValue }
    var title: String { String(localized: String.LocalizationValue("practice.metric.\(rawValue)")) }
    var unit: String { self == .speech ? "s" : "Hz" }
    func value(in result: PitcheeAnalysisResult) -> Double? {
        let value: Double?
        switch self {
        case .pitch: value = result.f0.meanHz
        case .variation: value = result.f0.standardDeviationHz
        case .speech: value = result.vad.speechSeconds
        }
        guard let value, value.isFinite, value >= 0, self != .pitch || value > 0 else { return nil }
        return value
    }
    func formatted(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "—" }
        return "\(value.formatted(.number.precision(.fractionLength(1)))) \(unit)"
    }
}

nonisolated enum PracticeFeedback: String, Codable, CaseIterable, Identifiable {
    case closer, similar, unsure
    var id: String { rawValue }
    var title: String { String(localized: String.LocalizationValue("practice.feedback.\(rawValue)")) }
}

/// Conservative recording checks, independent of VFP/naturalness/model scores.
/// These thresholds are provisional capture heuristics, not clinical judgements.
nonisolated struct RecordingQuality: Codable, Equatable, Sendable {
    enum Issue: String, Codable, CaseIterable {
        case shortSpeech, lowLevel, background, clipping, unavailable
        var advice: String { String(localized: String.LocalizationValue("practice.quality.\(rawValue)")) }
    }
    static let rulesVersion = "capture-quality-v1"
    let version: String
    let issues: [Issue]
    let backgroundMeasured: Bool
    var canCompare: Bool { version == Self.rulesVersion && issues.isEmpty }

    init(speechSeconds: Double, speechDBFS: Double?, backgroundDBFS: Double?, clippedFraction: Double?) {
        version = Self.rulesVersion
        var issues: [Issue] = []
        if !speechSeconds.isFinite || speechSeconds < 5 { issues.append(.shortSpeech) }
        if let speechDBFS, speechDBFS.isFinite, (-120...0).contains(speechDBFS) {
            if speechDBFS < -45 { issues.append(.lowLevel) }
        } else { issues.append(.unavailable) }
        backgroundMeasured = backgroundDBFS.map { $0.isFinite && (-120...0).contains($0) } ?? false
        if backgroundMeasured, let speechDBFS, speechDBFS.isFinite, let backgroundDBFS,
           speechDBFS - backgroundDBFS < 10 { issues.append(.background) }
        if let clippedFraction, clippedFraction.isFinite, (0...1).contains(clippedFraction) {
            if clippedFraction >= 0.01 { issues.append(.clipping) }
        } else if !issues.contains(.unavailable) { issues.append(.unavailable) }
        self.issues = issues
    }
}

/// Separate cohorts even when display names match: exact material, target,
/// scoring rules, quality rules, and model all influence comparability.
nonisolated struct PracticeCohort: Hashable, Identifiable {
    let kind: PracticeKind
    let target: VoicePreference
    let promptID: String
    let passage: String
    let scoringVersion: String
    let modelVersion: String
    let qualityVersion: String
    var id: Self { self }
}

nonisolated struct DailyPracticeSummary: Identifiable {
    let date: Date
    let median: Double
    let minimum: Double
    let maximum: Double
    let count: Int
    var id: Date { date }

    init?(date: Date, values: [Double]) {
        let sorted = values.filter(\.isFinite).sorted()
        guard let minimum = sorted.first, let maximum = sorted.last else { return nil }
        self.date = date
        self.minimum = minimum
        self.maximum = maximum
        count = sorted.count
        let middle = count / 2
        median = count.isMultiple(of: 2) ? sorted[middle - 1] / 2 + sorted[middle] / 2 : sorted[middle]
    }
}
