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

    init(
        id: UUID = UUID(),
        recordedAt: Date,
        result: PitcheeAnalysisResult
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
    }

    /// The complete result as returned by PitcheeCore.
    var result: PitcheeAnalysisResult? {
        try? Self.decoder.decode(PitcheeAnalysisResult.self, from: resultPayload)
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
    let sampleCount: Int
    let finalScore: Double?
    let naturalnessScore: Double?
    let meanPitchHz: Double?
    let speechSeconds: Double?

    init(assessments: [RecordingAssessment]) {
        sampleCount = assessments.count
        finalScore = Self.average(assessments.map(\.finalScore))
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
