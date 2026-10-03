//
//  RecordingAssessment.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/18.
//

import Foundation
import SwiftData

/// A persisted snapshot of one completed recording assessment.
///
/// Frequently displayed values are stored as columns so that trends can be
/// queried efficiently. `resultPayload` keeps the complete engine response,
/// including VAD segments and per-window scores, for future features.
@Model
final class RecordingAssessment {
    @Attribute(.unique) var id: UUID
    var recordedAt: Date

    var schemaVersion: Int
    var modelVersion: String

    var inputSeconds: Double
    var analyzedSeconds: Double
    var speechSeconds: Double
    var meanPitchHz: Double?

    var standardScore: Double
    var naturalnessScore: Double
    var finalScore: Double
    var scoreWasLimited: Bool

    var resultPayload: Data

    // Optional additions preserve pre-practice history without inventing a goal
    // or a quality judgement for recordings captured by older builds.
    var practicePayload: Data?
    var qualityPayload: Data?
    var recordedTargetRawValue: String?
    var scoringRulesVersion: String?
    var capturedFinalScore: Double?
    var comparedToID: UUID?
    var comparisonFeedbackRawValue: String?

    init(
        id: UUID = UUID(),
        recordedAt: Date,
        result: PitcheeAnalysisResult,
        preference: VoicePreference? = nil,
        practice: PracticeContext? = nil,
        quality: RecordingQuality? = nil,
        comparedToID: UUID? = nil
    ) throws {
        self.id = id
        self.recordedAt = recordedAt
        schemaVersion = result.schemaVersion
        modelVersion = result.modelVersion
        inputSeconds = result.audio.inputSeconds
        analyzedSeconds = result.audio.analyzedSeconds
        speechSeconds = result.vad.speechSeconds
        meanPitchHz = result.f0.meanHz
        standardScore = result.vfp.vfpStandardScore
        naturalnessScore = result.naturalness.score
        finalScore = result.composite.finalScore
        scoreWasLimited = result.composite.limited
        resultPayload = try Self.encoder.encode(result)
        practicePayload = try practice.map { try Self.encoder.encode($0) }
        qualityPayload = try quality.map { try Self.encoder.encode($0) }
        let target = practice?.target ?? preference
        recordedTargetRawValue = target?.rawValue
        scoringRulesVersion = practice?.scoringVersion ?? target.map { _ in VoiceDirectionScore.rulesVersion }
        capturedFinalScore = target.flatMap { $0 == .undecided ? nil : $0.score(for: result).finalScore }
        self.comparedToID = comparedToID
    }

    var practice: PracticeContext? { practicePayload.flatMap { try? Self.decoder.decode(PracticeContext.self, from: $0) } }
    var quality: RecordingQuality? { qualityPayload.flatMap { try? Self.decoder.decode(RecordingQuality.self, from: $0) } }
    var recordedTarget: VoicePreference? { recordedTargetRawValue.flatMap(VoicePreference.init(rawValue:)) }
    var isBaselineEligible: Bool { quality?.canCompare == true && cohort != nil }
    var cohort: PracticeCohort? {
        guard let practice, let quality else { return nil }
        return PracticeCohort(kind: practice.kind, target: practice.target,
                              promptID: practice.promptID, passage: practice.passage,
                              scoringVersion: practice.scoringVersion, modelVersion: modelVersion,
                              qualityVersion: quality.version)
    }

    /// The complete result as returned by PitcheeCore.
    var result: PitcheeAnalysisResult? {
        try? Self.decoder.decode(PitcheeAnalysisResult.self, from: resultPayload)
    }

    /// Re-evaluate existing recordings without rewriting their raw results.
    func finalScore(for preference: VoicePreference) -> Double {
        guard preference != .undecided else { return finalScore }
        if let result {
            return preference.score(for: result).finalScore
        }
        if preference == .masculine {
            return VoiceDirectionScore.masculineComposite(
                feminineScore: standardScore, naturalness: naturalnessScore, pitchHz: meanPitchHz
            ).finalScore
        }
        return finalScore
    }

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()
}

/// Derived dashboard values for all successfully persisted assessments.
///
/// This intentionally stays derived instead of being stored as another
/// mutable record. Saving a new assessment therefore makes the next query
/// produce a fresh baseline automatically, without a second source of truth.
struct RecordingAssessmentAverages {
    let finalScore: Double?
    let naturalnessScore: Double?
    let meanPitchHz: Double?
    let speechSeconds: Double?

    init(assessments: [RecordingAssessment], preference: VoicePreference = .undecided) {
        finalScore = Self.average(assessments.map { $0.finalScore(for: preference) })
        naturalnessScore = Self.average(assessments.map(\.naturalnessScore))
        meanPitchHz = Self.average(assessments.compactMap(\.meanPitchHz))
        speechSeconds = Self.average(assessments.map(\.speechSeconds))
    }

    private static func average(_ values: [Double]) -> Double? {
        let finiteValues = values.filter(\.isFinite)
        guard !finiteValues.isEmpty else { return nil }
        return finiteValues.reduce(0, +) / Double(finiteValues.count)
    }
}
