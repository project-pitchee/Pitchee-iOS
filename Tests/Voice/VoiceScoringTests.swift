//
//  VoiceScoringTests.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/30.
//

import Foundation

@main
enum VoiceScoringTests {
    static func main() throws {
        var checks = 0
        func check(_ condition: @autoclosure () -> Bool, _ message: String) {
            checks += 1
            precondition(condition(), message)
        }
        func close(_ left: Double, _ right: Double) -> Bool {
            abs(left - right) < 0.000_001
        }
        let rules = [
            "continuous": "continuous"
        ]
        let reference = try String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8)
        var observedRules = Set<String>()
        let rows = reference.split(separator: "\n")
        check(rows.count == 1530, "The full reference grid must be present")
        for row in rows {
            let cells = row.split(separator: "\t").map(String.init)
            check(cells.count == 9, "Reference row has all fields")
            let pitch = Double(cells[2])!
            let score = VoiceDirectionScore.masculineComposite(
                feminineScore: Double(cells[0])!, naturalness: Double(cells[1])!,
                pitchHz: pitch == 0 ? nil : pitch
            )
            check(close(score.baseScore, Double(cells[3])!), "Base matches Core: \(row)")
            check(close(score.finalScore, Double(cells[4])!), "Final matches Core: \(row)")
            check(score.cap == (Double(cells[5])! < 0 ? nil : Double(cells[5])), "Cap matches Core: \(row)")
            check(score.limited == (cells[6] == "1"), "Limited flag matches Core: \(row)")
            check(score.boosted == (cells[7] == "1"), "Boost flag matches Core: \(row)")
            check(score.rule == rules[cells[8]], "Rule matches Core: \(row)")
            observedRules.insert(score.rule)
        }
        check(observedRules == Set(rules.values), "Exercise every rule, including missing pitch")

        func result(
            pitch: Double? = 120,
            scoreProfile: String? = nil,
            composite: PitcheeAnalysisResult.CompositeScore = .init(
                baseScore: 24, finalScore: 23, cap: 23, rule: "stored-rule", limited: true, boosted: false
            ),
            naturalness: Double = 100
        ) -> PitcheeAnalysisResult {
            .init(
                schemaVersion: 2, modelVersion: "voice-scoring-tests",
                scoreProfile: scoreProfile,
                audio: .init(sourceSampleRate: 16_000, sourceChannels: 1, inputSeconds: 12, analyzedSeconds: 12),
                vad: .init(segmentCount: 0, speechSeconds: 10, sileroSegmentCount: 0, discardedBreathLikeCount: 0, trimmedSegmentCount: 0, segments: []),
                f0: .init(windowSeconds: 0.5, meanHz: pitch, standardDeviationHz: nil, voicedFrameCount: 0, voicedWindowCount: 0, windows: []),
                vfp: .init(vfpStandardScore: 20, windowCount: 0, windowDurationSeconds: 1, windows: []),
                naturalness: .init(score: naturalness, windowCount: 0, windowDurationSeconds: 1, windows: []),
                composite: composite
            )
        }
        let raw = result()
        let payload = try JSONEncoder().encode(raw)
        let masculine = VoicePreference.masculine.score(for: raw)
        check(masculine.standardScore == 80, "Masculine alignment complements feminine tendency")
        check(masculine.naturalnessScore == 100, "Naturalness does not change direction")
        check(masculine.finalScore == 84 && masculine.baseScore == 84, "Masculinization uses the Core continuous score")
        check(raw.composite.finalScore == 23 && raw.vfp.vfpStandardScore == 20, "Raw result remains unchanged")
        for preference in [VoicePreference.feminine, .undecided] {
            let score = preference.score(for: raw)
            check(score.standardScore == 20 && score.naturalnessScore == 100, "Other preferences preserve metrics")
            check(score.baseScore == 24 && score.finalScore == 23 && score.rule == "stored-rule", "Preserve the engine result verbatim")
            check(score.composite.cap == 23 && score.composite.limited && !score.composite.boosted, "Preserve engine flags")
        }
        let coreResult = result(
            scoreProfile: "masculinization",
            composite: .init(baseScore: 81, finalScore: 81, cap: nil, rule: "continuous", limited: false, boosted: false)
        )
        check(VoicePreference.masculine.score(for: coreResult).finalScore == 81,
              "Use the backend composite when the result declares masculinization")
        let switchedToFeminine = VoicePreference.feminine.score(for: coreResult)
        check(close(switchedToFeminine.finalScore, 32) && switchedToFeminine.rule == "low_f0_natural_cap",
              "Switching a masculinization result to feminine recomputes the matching Core profile")
        let decoded = try JSONDecoder().decode(PitcheeAnalysisResult.self, from: payload)
        check(VoicePreference.masculine.score(for: decoded).finalScore == masculine.finalScore, "Persisted raw results reproduce the displayed score")

        for pitch: Double? in [nil, 0, -1, .nan, .infinity, -.infinity] {
            let score = VoicePreference.masculine.score(for: result(pitch: pitch))
            check(score.finalScore == 69 && score.baseScore == 69, "Missing or invalid pitch removes only the F0 contribution")
            check(score.rule == "continuous" && score.composite.cap == nil, "Fallback uses Core's continuous masculinization rule")
        }
        let naturalnessIndependent = VoicePreference.masculine.score(for: result(naturalness: 0)).finalScore
        check(naturalnessIndependent == masculine.finalScore, "Masculinization ignores naturalness")
        for (stored, expected) in [("男性向声音", VoicePreference.masculine), ("女性向声音", .feminine), ("暂不确定", .undecided), ("masculine", .masculine), ("feminine", .feminine), ("undecided", .undecided)] {
            check(VoicePreference(legacyStoredValue: stored) == expected, "Restore both legacy and semantic preferences")
        }
        check(VoicePreference(legacyStoredValue: "invalid") == nil, "Unknown preferences are rejected")
        print("Voice scoring: \(checks) checks passed across \(rows.count) Core reference cases")
    }
}
