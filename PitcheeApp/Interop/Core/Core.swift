//
//  Core.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/13.
//

import CPitcheeCore
import Foundation

nonisolated public enum PitcheeCore {
    public static var version: String {
        String(cString: pitchee_core_version())
    }

    public static func bundledModelDirectory(in bundle: Bundle = .main) throws -> URL {
        guard let directory = bundle.url(forResource: "models", withExtension: nil) else {
            throw PitcheeCoreError(
                message: "The PitcheeCore model directory is missing from the app bundle."
            )
        }
        return directory
    }

    public static func compositeScore(
        standardScore: Double,
        naturalnessScore: Double,
        meanF0: Double?
    ) throws -> PitcheeAnalysisResult.CompositeScore {
        var rawScore = pitchee_composite_score_t()
        let status = pitchee_composite_score(
            standardScore,
            naturalnessScore,
            meanF0 ?? 0,
            meanF0 == nil ? 0 : 1,
            &rawScore
        )
        guard status == PITCHEE_SUCCESS else {
            throw PitcheeCoreError(status: status, message: "Unable to calculate the composite score.")
        }

        let rule = withUnsafeBytes(of: &rawScore.score_rule) { bytes in
            guard let address = bytes.baseAddress else { return "" }
            return String(cString: address.assumingMemoryBound(to: CChar.self))
        }

        return .init(
            baseScore: rawScore.base_score,
            finalScore: rawScore.final_score,
            cap: rawScore.has_score_cap == 0 ? nil : rawScore.score_cap,
            rule: rule,
            limited: rawScore.score_limited != 0,
            boosted: rawScore.score_boosted != 0
        )
    }
}
