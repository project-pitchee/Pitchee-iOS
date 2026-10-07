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

/// Scalar fields needed by history and scoring. Window/segment arrays belong to
/// detail views and are deliberately not decoded or retained by this projection.
nonisolated struct VoiceAnalysisSummary: Decodable, Sendable {
    let scoreProfile: String?
    let standardScore: Double
    let naturalnessScore: Double
    let pitchHz: Double?
    let pitchVariationHz: Double?
    let composite: PitcheeAnalysisResult.CompositeScore

    init(result: PitcheeAnalysisResult) {
        scoreProfile = result.scoreProfile
        standardScore = result.vfp.vfpStandardScore
        naturalnessScore = result.naturalness.score
        pitchHz = result.f0.meanHz
        pitchVariationHz = result.f0.standardDeviationHz
        composite = result.composite
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scoreProfile = try container.decodeIfPresent(String.self, forKey: .scoreProfile)
        let pitch = try container.nestedContainer(keyedBy: PitchKeys.self, forKey: .f0)
        pitchHz = try pitch.decodeIfPresent(Double.self, forKey: .meanHz)
        pitchVariationHz = try pitch.decodeIfPresent(Double.self, forKey: .standardDeviationHz)
        let voice = try container.nestedContainer(keyedBy: VoiceKeys.self, forKey: .vfp)
        standardScore = try voice.decode(Double.self, forKey: .vfpStandardScore)
        let naturalness = try container.nestedContainer(keyedBy: NaturalnessKeys.self, forKey: .naturalness)
        naturalnessScore = try naturalness.decode(Double.self, forKey: .score)
        composite = try container.decode(PitcheeAnalysisResult.CompositeScore.self, forKey: .composite)
    }

    private enum CodingKeys: String, CodingKey { case scoreProfile, f0, vfp, naturalness, composite }
    private enum PitchKeys: String, CodingKey { case meanHz, standardDeviationHz }
    private enum VoiceKeys: String, CodingKey { case vfpStandardScore }
    private enum NaturalnessKeys: String, CodingKey { case score }
}

/// A presentation of the immutable engine result for the current practice goal.
/// VFP remains a feminine reference score in storage and in the two-sided chart.
/// New analyses request Core's explicit masculinization profile. The local
/// formula remains as a compatibility path for older stored results that do not
/// contain `score_profile` in their JSON payload.
nonisolated struct VoiceDirectionScore {
    static let rulesVersion = "core-score-profile-v1"
    let standardScore: Double
    let naturalnessScore: Double
    let composite: PitcheeAnalysisResult.CompositeScore

    var baseScore: Double { composite.baseScore }
    var finalScore: Double { composite.finalScore }
    var rule: String { composite.rule }

    init(preference: VoicePreference, result: PitcheeAnalysisResult) {
        self.init(preference: preference, summary: VoiceAnalysisSummary(result: result))
    }

    init(preference: VoicePreference, summary: VoiceAnalysisSummary) {
        naturalnessScore = summary.naturalnessScore
        if preference == .masculine {
            standardScore = 100 - Self.clamp(summary.standardScore, to: 100)
            if summary.scoreProfile == "masculinization" {
                composite = summary.composite
            } else {
                composite = Self.masculineComposite(
                    feminineScore: summary.standardScore,
                    naturalness: summary.naturalnessScore,
                    pitchHz: summary.pitchHz
                )
            }
        } else if preference == .feminine, summary.scoreProfile == "masculinization" {
            standardScore = Self.clamp(summary.standardScore, to: 100)
            composite = Self.feminineComposite(
                standardScore: summary.standardScore,
                naturalness: summary.naturalnessScore,
                pitchHz: summary.pitchHz
            )
        } else {
            // Preserve the engine's original result for feminine/undecided
            // results that already use the matching profile or an older schema.
            standardScore = summary.standardScore
            composite = summary.composite
        }
    }

    static func masculineComposite(
        feminineScore: Double, naturalness: Double, pitchHz: Double?
    ) -> PitcheeAnalysisResult.CompositeScore {
        _ = naturalness // The Core masculinization profile intentionally ignores it.
        let vfpDeviation = clamp((50 - clamp(feminineScore, to: 100)) / 50, lower: -1, upper: 1)
        let f0Deviation: Double
        if let pitchHz, pitchHz.isFinite, pitchHz > 0 {
            f0Deviation = clamp((165 - pitchHz) / 75, lower: -1, upper: 1)
        } else {
            f0Deviation = 0
        }
        let score = clamp(60 + 25 * f0Deviation + 15 * vfpDeviation, to: 100)
        return .init(baseScore: score, finalScore: score, cap: nil,
                     rule: "continuous", limited: false, boosted: false)
    }

    /// Reconstruct the feminine profile when a masculine-profile recording is
    /// viewed after the user switches direction. New analyses already carry
    /// the matching Core composite; this path keeps direction switching local
    /// and does not rewrite the stored result payload.
    static func feminineComposite(
        standardScore: Double, naturalness: Double, pitchHz: Double?
    ) -> PitcheeAnalysisResult.CompositeScore {
        let standard = clamp(standardScore, to: 100)
        let naturalness = clamp(naturalness, to: 100)
        guard let pitchHz, pitchHz.isFinite, pitchHz > 0 else {
            return .init(baseScore: standard, finalScore: standard, cap: nil,
                         rule: "f0_unavailable", limited: false, boosted: false)
        }

        let standardRatio = standard / 100
        let naturalnessRatio = clamp((naturalness - 40) / 50, to: 1)
        let f0Ratio = clamp((pitchHz - 110) / 90, to: 1)
        let base = 100 * (
            0.50 * standardRatio
                + 0.20 * naturalnessRatio
                + 0.15 * f0Ratio
                + 0.15 * standardRatio * naturalnessRatio * f0Ratio
        )

        var score = base
        var cap: Double?
        var rule = "continuous"
        var boosted = false
        if pitchHz > 165 && naturalness > 80 && standard > 50 {
            let strength = min(
                (pitchHz - 165) / 25,
                (naturalness - 80) / 20,
                (standard - 50) / 30,
                1
            )
            let promoted = 60 + 40 * strength
            if promoted > score {
                score = promoted
                boosted = true
            }
            rule = "pass_boost"
        } else if pitchHz > 165 && naturalness < 50 {
            cap = 30
            rule = "high_f0_stylized_cap"
        } else if pitchHz <= 165 && naturalness >= 50 {
            cap = 59
            rule = "low_f0_natural_cap"
        } else if pitchHz <= 165 && naturalness < 50 {
            cap = 20
            rule = "low_f0_stylized_cap"
        } else if pitchHz > 165 && naturalness >= 50 && standard < 50 {
            cap = 59
            rule = "high_f0_male_cap"
        }

        let final = clamp(cap.map { min(score, $0) } ?? score, to: 100)
        return .init(baseScore: base, finalScore: final, cap: cap, rule: rule,
                     limited: cap != nil && final < score, boosted: boosted)
    }

    private static func clamp(_ value: Double, to upper: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), upper)
    }

    private static func clamp(_ value: Double, lower: Double, upper: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, lower), upper)
    }
}
