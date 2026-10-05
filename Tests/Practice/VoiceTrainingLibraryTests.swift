import Foundation

@main
enum VoiceTrainingLibraryTests {
    static func main() throws {
        let store = VoiceTrainingLibraryStore.shared
        assert(store.articles.count == 49)
        for article in store.articles {
            assert(article.sections.map(\.iconName) == ["gearshape.2.fill", "stethoscope", "figure.run", "books.vertical.fill"])
            assert(article.sections.allSatisfy { $0.body.count >= 80 })
        }

        func quality(_ speech: Double = 8, level: Double? = -25, background: Double? = -50, clipped: Double? = 0) -> RecordingQuality {
            RecordingQuality(speechSeconds: speech, speechDBFS: level, backgroundDBFS: background, clippedFraction: clipped)
        }
        func result(
            pitch: Double? = 200, deviation: Double? = 22, standard: Double = 80,
            naturalness: Double = 85, speech: Double = 8, score: Double? = nil,
            rule: String? = nil, scoreProfile: String? = nil, model: String = "test",
            pitchFrames: Int? = nil, pitchWindows: Int? = nil,
            standardWindows: Int = 10, naturalnessWindows: Int = 10
        ) -> PitcheeAnalysisResult {
            let calculated = scoreProfile == "masculinization"
                ? VoiceDirectionScore.masculineComposite(feminineScore: standard, naturalness: naturalness, pitchHz: pitch)
                : VoiceDirectionScore.feminineComposite(standardScore: standard, naturalness: naturalness, pitchHz: pitch)
            return PitcheeAnalysisResult(
                schemaVersion: 3, modelVersion: model, scoreProfile: scoreProfile,
                audio: .init(sourceSampleRate: 16_000, sourceChannels: 1, inputSeconds: speech, analyzedSeconds: speech),
                vad: .init(segmentCount: 1, speechSeconds: speech, sileroSegmentCount: 1, discardedBreathLikeCount: 0, trimmedSegmentCount: 0, segments: []),
                f0: .init(windowSeconds: 0.5, meanHz: pitch, standardDeviationHz: deviation,
                          voicedFrameCount: pitchFrames ?? (pitch == nil ? 0 : 100),
                          voicedWindowCount: pitchWindows ?? (pitch == nil ? 0 : 10), windows: []),
                vfp: .init(vfpStandardScore: standard, windowCount: standardWindows, windowDurationSeconds: 1, windows: []),
                naturalness: .init(score: naturalness, windowCount: naturalnessWindows, windowDurationSeconds: 1, windows: []),
                composite: .init(baseScore: calculated.baseScore, finalScore: score ?? calculated.finalScore,
                                 cap: calculated.cap, rule: rule ?? calculated.rule,
                                 limited: calculated.limited, boosted: calculated.boosted)
            )
        }
        func recommend(_ sample: PitcheeAnalysisResult, _ preference: VoicePreference = .feminine, quality capture: RecordingQuality? = RecordingQuality(speechSeconds: 8, speechDBFS: -25, backgroundDBFS: -50, clippedFraction: 0), volume: RecordingVolumeStatistics? = nil) -> VoiceTrainingRecommendation {
            VoiceLibraryMatcher.recommend(for: sample, preference: preference, quality: capture, volumeStatistics: volume, store: store)
        }
        func IDs(_ recommendation: VoiceTrainingRecommendation) -> [String] {
            recommendation.prioritySuggestions.map(\.id)
        }
        func articles(_ recommendation: VoiceTrainingRecommendation) -> [String] {
            recommendation.combinedArticles.map(\.id)
        }
        func assertCaptureOnly(_ recommendation: VoiceTrainingRecommendation) {
            assert(recommendation.matchedRule == "recording_quality")
            assert(recommendation.prioritySuggestions.allSatisfy { $0.id.hasPrefix("capture") })
            assert(recommendation.combinedArticles.allSatisfy { $0.id.hasPrefix("QUALITY-") })
            assert(recommendation.acousticAlertArticles.isEmpty && recommendation.deepDiveArticles.isEmpty)
        }

        let good = result()
        let pass = recommend(good)
        assert(IDs(pass) == ["dailySpeech", "listen"])
        assert(pass.primaryArticle?.id == "RULE-PASS-BOOST-01")
        assertCaptureOnly(recommend(good, quality: nil))
        assertCaptureOnly(recommend(good, quality: quality(level: nil, clipped: nil)))
        let staleQuality = try JSONDecoder().decode(RecordingQuality.self, from: Data("""
        {"version":"capture-quality-old","issues":[],"backgroundMeasured":true}
        """.utf8))
        assertCaptureOnly(recommend(good, quality: staleQuality))
        print("✓ Valid persisted quality supports personalization; unavailable or stale quality does not")

        let short = recommend(result(speech: 3), quality: quality(3))
        assert(IDs(short) == ["captureDuration"])
        assert(short.prioritySuggestions.first?.article == nil)
        assertCaptureOnly(short)
        assertCaptureOnly(recommend(result(speech: 3))) // Contradictory persisted quality cannot hide short speech.
        assertCaptureOnly(recommend(result(speech: .nan)))
        let simultaneous = recommend(result(speech: 3), quality: quality(3, level: -48, background: -50, clipped: 0.02))
        assert(IDs(simultaneous) == ["captureClipping", "captureEnvironment"])
        assertCaptureOnly(simultaneous)
        assert(IDs(recommend(good, quality: quality(background: -28))) == ["captureEnvironment"])
        assert(IDs(recommend(good, quality: quality(level: -50))) == ["captureEnvironment"])
        print("✓ Short, quiet, noisy and clipped recordings yield up to two capture steps without physiological guesses")

        let cleanVolume = RecordingVolumeStatistics(environmentDBFS: -50, averageDBFS: -25, medianDBFS: -25,
            high95DBFS: -20, low5DBFS: -30, windows: [.init(centerSeconds: 0, voiceDBFS: nil, backgroundDBFS: -50)], clippedSampleFraction: 0)
        var clippedVolume = cleanVolume
        clippedVolume.clippedSampleFraction = 0.1
        assert(IDs(recommend(good, quality: nil, volume: cleanVolume)) == ["dailySpeech", "listen"])
        assertCaptureOnly(recommend(good, volume: clippedVolume))
        print("✓ Fresh measurements can establish quality or reveal a failure despite a saved passing assessment")

        for preference in VoicePreference.allCases {
            for invalidPitch in [nil, Double.nan, Double.infinity, -5, 0] as [Double?] {
                let unavailable = recommend(result(pitch: invalidPitch), preference)
                assert(IDs(unavailable) == ["pitchUnavailable"])
                assert(unavailable.combinedArticles.isEmpty)
            }
            assert(IDs(recommend(result(pitchFrames: 0), preference)) == ["pitchUnavailable"])
            assert(IDs(recommend(result(pitchWindows: 0), preference)) == ["pitchUnavailable"])
            assert(IDs(recommend(result(pitchWindows: 1), preference)) == ["pitchUnavailable"])
            for invalidScore in [Double.nan, Double.infinity, -1, 101] {
                assert(IDs(recommend(result(standard: invalidScore), preference)) == ["analysisUnavailable"])
                assert(IDs(recommend(result(naturalness: invalidScore), preference)) == ["analysisUnavailable"])
            }
            assert(IDs(recommend(result(standardWindows: 0), preference)) == ["analysisUnavailable"])
            assert(IDs(recommend(result(naturalnessWindows: 0), preference)) == ["analysisUnavailable"])
        }
        assert(IDs(recommend(result(score: .nan))) == ["analysisUnavailable"])
        print("✓ Missing pitch, non-finite scores and absent measurement windows never trigger corrective voice training")

        for rule in ["pass_boost", "high_f0_stylized_cap", "high_f0_male_cap", "low_f0_natural_cap", "continuous"] {
            let neutral = recommend(result(rule: rule), .undecided)
            assert(IDs(neutral) == ["explore", "listen"])
            assert(neutral.matchedRule == "nonbinary_exploration")
            assert(neutral.primaryArticle?.id == "NONBINARY-EXPLORE-01")
        }
        for pitch in [90.0, 140, 180, 270] {
            let masculine = recommend(result(pitch: pitch), .masculine)
            assert(IDs(masculine) == ["masculineBasics", "listen"])
            assert(!articles(masculine).contains(where: { $0.contains("PRE-T") || $0.contains("ON-T") }))
        }
        assert(IDs(recommend(result(pitch: 80), .masculine)) == ["masculineComfort", "listen"])
        print("✓ Goal changes do not inherit feminine rules, a lower-pitch prescription, or assumed hormone status")

        for preference in VoicePreference.allCases {
            for sample in [result(pitch: 135, naturalness: 35), result(pitch: 280, naturalness: 49), result(naturalness: 69.9)] {
                let ease = recommend(sample, preference)
                assert(IDs(ease) == ["comfortableVoice", "listen"])
                assert(ease.primaryArticle?.id == "HEALTH-HYGIENE-01")
            }
        }
        assert(IDs(recommend(result(pitch: 145, standard: 55, naturalness: 78))) == ["pitchGlide", "listen"])
        assert(IDs(recommend(result(pitch: 195, standard: 35, naturalness: 75))) == ["resonance", "listen"])
        assert(IDs(recommend(result(pitch: 280))) == ["pitchComfort", "listen"])
        assert(!articles(recommend(result(pitch: 280))).contains("RULE-PASS-BOOST-01"))
        assert(IDs(recommend(result(deviation: 3))) == IDs(pass))
        assert(IDs(recommend(result(deviation: 80))) == IDs(pass))
        print("✓ Comfort takes priority; incompatible pitch cues and diagnoses from aggregate variation are suppressed")

        for (score, articleID) in [(49.9, "SCORE-STARTER-01"), (50.0, "SCORE-MID-01"), (74.9, "SCORE-MID-01"), (75.0, "SCORE-ADVANCED-01"), (89.9, "SCORE-ADVANCED-01"), (90.0, "SCORE-MASTER-01")] {
            assert(recommend(result(score: score, rule: "continuous")).primaryArticle?.id == articleID)
        }
        let samples = [good, result(pitch: 145), result(pitch: 280), result(naturalness: 40), result(pitch: 80), result(standard: 30)]
        for preference in VoicePreference.allCases {
            for sample in samples {
                let recommendation = recommend(sample, preference)
                assert((1...2).contains(recommendation.prioritySuggestions.count))
                assert(Set(IDs(recommendation)).count == recommendation.prioritySuggestions.count)
                assert(Set(articles(recommendation)).count == recommendation.combinedArticles.count)
                assert(recommendation.combinedArticles.count <= 2)
                assert(recommendation.combinedArticles.allSatisfy { $0.targetPreferences.contains(preference.rawValue) })
                assert(recommendation.prioritySuggestions.allSatisfy { !$0.title.isEmpty && !$0.detail.isEmpty })
                assert(IDs(recommendation) == IDs(recommend(sample, preference)))
            }
        }
        print("✓ Score boundaries, deterministic ordering, direction filtering and the two-suggestion limit hold")

        let drop = VoiceLibraryMatcher.recommendForPractice(scoreA: 90, scoreB: 40, store: store)
        assert(IDs(drop) == ["compareDrop"])
        assert(drop.primaryArticle?.id == "PRACTICE-AB-SUBJECTIVE-01")
        assert(IDs(VoiceLibraryMatcher.recommendForPractice(scoreA: 40, scoreB: 90, store: store)) == ["compare"])
        assert(IDs(VoiceLibraryMatcher.recommendForPractice(scoreA: 90, scoreB: 40, feedback: .unsure, store: store)) == ["listen"])
        assert(IDs(VoiceLibraryMatcher.recommendForPractice(scoreA: .nan, scoreB: 40, store: store)) == ["analysisUnavailable"])
        assertCaptureOnly(VoiceLibraryMatcher.recommendForPractice(resultA: good, resultB: good, store: store))
        assertCaptureOnly(VoiceLibraryMatcher.recommendForPractice(resultA: good, resultB: good, qualityA: quality(), qualityB: quality(clipped: 0.1), store: store))
        let changedModel = VoiceLibraryMatcher.recommendForPractice(resultA: good, resultB: result(model: "other"), qualityA: quality(), qualityB: quality(), store: store)
        assert(IDs(changedModel) == ["compareConditions"])
        let undecided = VoiceLibraryMatcher.recommendForPractice(resultA: good, resultB: result(naturalness: 40), preference: .undecided, qualityA: quality(), qualityB: quality(), store: store)
        assert(IDs(undecided) == ["listen"])
        // Raw feminine scores fall as pitch falls; the selected masculine score rises.
        let masculineComparison = VoiceLibraryMatcher.recommendForPractice(resultA: result(pitch: 220), resultB: result(pitch: 110), preference: .masculine, qualityA: quality(), qualityB: quality(), store: store)
        assert(IDs(masculineComparison) == ["compare"])
        print("✓ A/B guidance respects capture quality, scoring compatibility, goal and listening feedback")

        assert(!store.search(query: "吸管").isEmpty)
        assert(store.articles(inCategory: "Module-01").count == 15)
        print("All Voice Training Library tests passed.")
    }
}
