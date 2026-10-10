//
//  VoiceTrainingLibraryTests.swift
//  Pitchee
//
//  Created by Ryo on 2026/10/5.
//

import Foundation

@main
enum VoiceTrainingLibraryTests {
    @MainActor
    static func main() async throws {
        guard CommandLine.arguments.count == 2 else { fatalError("Pass the test resource directory explicitly") }
        let directory = URL(fileURLWithPath: CommandLine.arguments[1])
        let store = try await VoiceTrainingLibraryStore.load(directory: directory)
        await testLoading(store: store)
        try testInvalidResources(directory: directory)
        for heading in ["机制", "Understanding", "Comprendre", "الفهم"] {
            assert(VoiceArticle.Section(heading: heading, body: "Body").iconName == "doc.text.fill")
            assert(VoiceArticle.Section(heading: heading, icon: "figure.run", body: "Body").iconName == "figure.run")
        }
        assert(store.articles.count == 49)
        for article in store.articles {
            assert(article.sections.map(\.iconName) == ["gearshape.2.fill", "stethoscope", "figure.run", "books.vertical.fill"])
            assert(article.sections.allSatisfy { $0.body.count >= 80 })
        }

        assert(store.categories.map(\.id) == Set(store.articles.map(\.category)).sorted())
        for category in store.categories {
            let expected = store.articles.filter { $0.category == category.id }
            assert(category.articles == expected)
            assert(store.articles(inCategory: category.id) == expected)
            assert(category.title == expected.first?.categoryDisplayTitle)
        }
        for query in ["", "  \n", "吸管", "RULE", "f0", "no-matching-article-xyz"] {
            for category in [nil, "", "Module-01-Engine-Rules", "Module-04-Masculine-Voice", "missing"] as [String?] {
                for preference in [nil, .feminine, .masculine, .undecided] as [VoicePreference?] {
                    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    let expected = store.articles.filter { article in
                        if let category, !category.isEmpty, article.category != category { return false }
                        if let preference, !article.targetPreferences.contains(preference.rawValue) { return false }
                        return trimmed.isEmpty || [article.title, article.summary, article.coreGoal, article.id, article.rawContent]
                            .contains { $0.localizedCaseInsensitiveContains(trimmed) }
                    }
                    assert(store.search(query: query, category: category, preference: preference) == expected)
                    if preference == nil {
                        let groups = store.categories(matching: query, category: category)
                        let expectedGroups = Dictionary(grouping: expected, by: \.category)
                        assert(groups.map(\.id) == expectedGroups.keys.sorted())
                        assert(groups.allSatisfy { $0.articles == expectedGroups[$0.id] })
                    }
                }
            }
        }
        print("✓ Indexed categories and searches preserve article order, category prefixes, goal filters and current localized titles")

        let parser = ArticleBodyParser()
        let markdown = """
        ### 小标题
        一段 **强调** 文字。
        - 一级条目
          * 二级条目
        2. 编号条目
        3、另一个编号
        | 指标 | 说明 |
        | --- | --- |
        | F0 | 频率 |
        ---
        #### 第二标题
        """
        let document = parser.document(for: markdown)
        assert(document === parser.document(for: markdown))
        assert(document.elements == [
            .subheading(id: "elem-1", text: "小标题"),
            .paragraph(id: "elem-2", text: "一段 **强调** 文字。"),
            .bulletItem(id: "elem-3", level: 0, text: "一级条目"),
            .bulletItem(id: "elem-4", level: 1, text: "二级条目"),
            .numberedItem(id: "elem-5", number: "2", text: "编号条目"),
            .numberedItem(id: "elem-6", number: "3", text: "另一个编号"),
            .table(id: "elem-7", headers: ["指标", "说明"], rows: [["F0", "频率"]]),
            .divider(id: "elem-8"),
            .subheading(id: "elem-9", text: "第二标题")
        ])
        let translated = parser.document(for: "### Updated heading\nChanged **content**.")
        assert(translated !== document)
        assert(translated.elements == [.subheading(id: "elem-1", text: "Updated heading"),
                                        .paragraph(id: "elem-2", text: "Changed **content**.")])
        assert(parser.document(for: "").elements.isEmpty)
        assert(parser.document(for: markdown) !== document) // The cache retains one source, not all prior articles.
        for article in store.articles {
            for section in article.sections {
                let parsed = parser.document(for: section.body)
                assert(!parsed.elements.isEmpty && Set(parsed.elements.map(\.id)).count == parsed.elements.count)
                assert(parser.document(for: section.body) === parsed)
            }
        }
        print("✓ Markdown is reused for unchanged sections; changed or localized text immediately replaces the single cached document")

        for _ in 0..<3 {
            assert(RichInlineText.normalizedMathText(#"Inline \(f_0\), display \[x + y\]."#)
                   == "Inline $f_0$, display $$x + y$$.")
            assert(RichInlineText.normalizedMathText(#"Incomplete \(x"#) == #"Incomplete \(x"#)
            assert(RichInlineText.normalizedMathText(#"Nested \(x \(y\)\)"#) == #"Nested \(x \(y\)\)"#)
            assert(RichInlineText.normalizedMathText(#"Escaped \\(x\\)"#) == #"Escaped \\(x\\)"#)
            assert(RichInlineText.normalizedMathText(#"Empty \( \)"#) == #"Empty \( \)"#)
        }
        assert(RichInlineText.isStandaloneDisplayMath(" $$x + y$$ "))
        assert(!RichInlineText.isStandaloneDisplayMath("$$x$$ and $$y$$"))
        print("✓ Shared math matching preserves inline, display, escaped, incomplete and nested delimiters")

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

    @MainActor
    private static func testLoading(store: VoiceTrainingLibraryStore) async {
        actor Attempts {
            private var count = 0
            let failFirst: Bool
            init(failFirst: Bool = false) { self.failFirst = failFirst }
            func load(_ store: VoiceTrainingLibraryStore) async throws -> VoiceTrainingLibraryStore {
                count += 1
                if failFirst && count == 1 {
                    throw VoiceTrainingLibraryStore.LoadError.missingResource("test")
                }
                // Yield so overlapping callers can join the same load.
                await Task.yield()
                return store
            }
            func total() -> Int { count }
        }
        let attempts = Attempts()
        let loader = VoiceTrainingLibraryLoader { try await attempts.load(store) }
        assert(loader.store.articles.isEmpty && !loader.isLoading && loader.error == nil)
        let initialAttempts = await attempts.total()
        assert(initialAttempts == 0, "Initializing a view's shared loader must not start disk I/O")
        async let first: Void = loader.load()
        async let second: Void = loader.load()
        _ = await (first, second)
        assert(loader.store.articles.count == 49 && !loader.isLoading && loader.error == nil)
        await loader.load()
        let loadedAttempts = await attempts.total()
        assert(loadedAttempts == 1, "Concurrent and later callers must reuse the loaded snapshot")

        let failing = Attempts(failFirst: true)
        let retryLoader = VoiceTrainingLibraryLoader { try await failing.load(store) }
        await retryLoader.load()
        assert(retryLoader.error != nil && retryLoader.store.articles.isEmpty && !retryLoader.isLoading)
        await retryLoader.load()
        assert(retryLoader.error == nil && retryLoader.store.articles.count == 49)
        let retryAttempts = await failing.total()
        assert(retryAttempts == 2, "A failed load must allow an explicit retry")

        do {
            _ = try await VoiceTrainingLibraryStore.load(bundle: .main)
            assertionFailure("The standalone test bundle has no JSON resources; source-path fallback must not occur")
        } catch {
            assert(error is VoiceTrainingLibraryStore.LoadError)
        }
        print("✓ Loading is asynchronous, shared, explicit about missing resources, and retryable")
    }

    private static func testInvalidResources(directory: URL) throws {
        let library = try Data(contentsOf: directory.appendingPathComponent("voice-training-library.json"))
        let matrix = try Data(contentsOf: directory.appendingPathComponent("voice-rule-matching-matrix.json"))
        func rejects(_ libraryData: Data, _ matrixData: Data) {
            do {
                _ = try VoiceTrainingLibraryStore(libraryData: libraryData, matrixData: matrixData)
                assertionFailure("Malformed library data must report a load failure")
            } catch {
                assert(error is VoiceTrainingLibraryStore.LoadError)
            }
        }
        rejects(Data("broken JSON".utf8), matrix)
        rejects(library, Data("{}".utf8))
        rejects(library, Data(#"{"missing": ["UNKNOWN-ARTICLE"]}"#.utf8))
        var payload = try JSONSerialization.jsonObject(with: library) as! [String: Any]
        payload["schemaVersion"] = "unsupported"
        rejects(try JSONSerialization.data(withJSONObject: payload), matrix)
        payload["schemaVersion"] = "1.0.0"
        payload["totalArticles"] = 0
        rejects(try JSONSerialization.data(withJSONObject: payload), matrix)
        var articles = payload["articles"] as! [[String: Any]]
        payload["totalArticles"] = articles.count
        articles[1]["id"] = articles[0]["id"]
        payload["articles"] = articles
        rejects(try JSONSerialization.data(withJSONObject: payload), matrix)
        print("✓ Invalid JSON, schema, counts, duplicate IDs and broken article references are rejected")
    }

}
