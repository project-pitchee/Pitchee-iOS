//
//  VoiceScoring.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/30.
//

import Foundation

nonisolated enum VoicePreference: String, Codable, CaseIterable, Identifiable, Sendable {
    case masculine
    case feminine
    case undecided

    var id: String { rawValue }

    /// Accept the display strings persisted by builds before semantic keys.
    init?(legacyStoredValue: String) {
        switch legacyStoredValue {
        case "男性向声音": self = .masculine
        case "女性向声音": self = .feminine
        case "暂不确定": self = .undecided
        default:
            guard let value = Self(rawValue: legacyStoredValue) else { return nil }
            self = value
        }
    }

    func score(for result: PitcheeAnalysisResult) -> VoiceDirectionScore {
        VoiceDirectionScore(preference: self, result: result)
    }
}

/// A presentation of the immutable engine result for the current practice goal.
/// VFP remains a feminine probability in storage and in the two-sided chart.
/// Masculine scoring mirrors the engine's pitch reference (110...200 Hz) and
/// its rules around 155 Hz: the 165 Hz threshold becomes 145 Hz, and the
/// boost reaches full pitch strength at 120 Hz. Keep this in sync with Core's
/// scoring.cpp; test-voice-scoring.sh compares both implementations.
nonisolated struct VoiceDirectionScore {
    static let rulesVersion = "directional-core-v1"
    let standardScore: Double
    let naturalnessScore: Double
    let composite: PitcheeAnalysisResult.CompositeScore

    var baseScore: Double { composite.baseScore }
    var finalScore: Double { composite.finalScore }
    var rule: String { composite.rule }

    init(preference: VoicePreference, result: PitcheeAnalysisResult) {
        naturalnessScore = result.naturalness.score
        if preference == .masculine {
            standardScore = 100 - Self.clamp(result.vfp.vfpStandardScore, to: 100)
            composite = Self.masculineComposite(
                feminineScore: result.vfp.vfpStandardScore,
                naturalness: result.naturalness.score,
                pitchHz: result.f0.meanHz
            )
        } else {
            // Preserve the engine's original result for feminine and undecided.
            standardScore = result.vfp.vfpStandardScore
            composite = result.composite
        }
    }

    static func masculineComposite(
        feminineScore: Double, naturalness: Double, pitchHz: Double?
    ) -> PitcheeAnalysisResult.CompositeScore {
        let standard = 100 - clamp(feminineScore, to: 100)
        let naturalness = clamp(naturalness, to: 100)
        guard let pitchHz, pitchHz.isFinite, pitchHz > 0 else {
            return .init(baseScore: standard, finalScore: standard, cap: nil,
                         rule: "masculine_f0_unavailable", limited: false, boosted: false)
        }

        let sr = standard / 100
        let nr = clamp((naturalness - 40) / 50, to: 1)
        let fr = clamp((200 - pitchHz) / 90, to: 1)
        let base = 100 * (0.50 * sr + 0.20 * nr + 0.15 * fr + 0.15 * sr * nr * fr)
        var score = base
        var cap: Double?
        var rule = "masculine_continuous"
        var boosted = false

        if pitchHz < 145, naturalness > 80, standard > 50 {
            let strength = min((145 - pitchHz) / 25, (naturalness - 80) / 20,
                               (standard - 50) / 30, 1)
            let promoted = 60 + 40 * strength
            boosted = promoted > score
            score = max(score, promoted)
            rule = "masculine_pass_boost"
        } else if pitchHz < 145, naturalness < 50 {
            cap = 30
            rule = "masculine_low_pitch_stylized_cap"
        } else if pitchHz >= 145, naturalness >= 50 {
            cap = 59
            rule = "masculine_high_pitch_cap"
        } else if pitchHz >= 145, naturalness < 50 {
            cap = 20
            rule = "masculine_high_pitch_stylized_cap"
        } else if pitchHz < 145, naturalness >= 50, standard < 50 {
            cap = 59
            rule = "masculine_low_pitch_feminine_cap"
        }

        let final = clamp(cap.map { min(score, $0) } ?? score, to: 100)
        return .init(baseScore: base, finalScore: final, cap: cap, rule: rule,
                     limited: cap != nil && final < score, boosted: boosted)
    }

    private static func clamp(_ value: Double, to upper: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), upper)
    }
}
