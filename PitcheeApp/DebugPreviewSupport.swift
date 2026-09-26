//
//  DebugPreviewSupport.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/26.
//

#if DEBUG
import Combine
import Darwin
import Foundation
import SwiftData
import SwiftUI

enum DebugPreviewRuntime {
    static var isRunning: Bool {
        // Reading the process environment through Foundation asks Objective-C
        // for `+[NSProcessInfo processInfo]`. Preview's JIT host can expose an
        // incomplete NSProcessInfo class, which causes an uncaught selector
        // exception before the first view is rendered. getenv is available in
        // both the app and Canvas and avoids that runtime dependency.
        guard let value = getenv("XCODE_RUNNING_FOR_PREVIEWS") else { return false }
        return String(cString: value) == "1"
    }
}

/// Deterministic data used only by SwiftUI previews.
/// Keeping it here makes result, export, and chart previews show the same
/// realistic recording without touching the app's persistence layer.
enum DebugPreviewData {
    static let result = makeResult()
    static let recordedAt = Date(timeIntervalSince1970: 1_790_395_200)
    static let history = [
        makeResult(meanPitchHz: 156, standardScore: 55, naturalnessScore: 66, finalScore: 64),
        makeResult(meanPitchHz: 165, standardScore: 62, naturalnessScore: 72, finalScore: 74),
        result
    ]

    private static func makeResult(
        meanPitchHz: Double = 174,
        standardScore: Double = 68,
        naturalnessScore: Double = 78,
        finalScore: Double = 82
    ) -> PitcheeAnalysisResult {
        let pitchWindows: [PitcheeAnalysisResult.PitchWindow] = (0..<24).map { index in
            let start = Double(index) * 0.5
            let pitch: Double? = index == 5 || index == 17
                ? nil
                : meanPitchHz + sin(Double(index) * 0.65) * 18
            return .init(
                startSeconds: start,
                endSeconds: start + 0.5,
                f0Hz: pitch
            )
        }
        let segments = [
            PitcheeAnalysisResult.Segment(
                startSeconds: 0.5,
                endSeconds: 5.5,
                speechStartSeconds: 0.6,
                speechEndSeconds: 5.4
            ),
            PitcheeAnalysisResult.Segment(
                startSeconds: 6.5,
                endSeconds: 11.5,
                speechStartSeconds: 6.6,
                speechEndSeconds: 11.4
            )
        ]
        let vfpWindows = (0..<12).map { index in
            PitcheeAnalysisResult.VFPWindow(
                startSeconds: Double(index),
                endSeconds: Double(index + 1),
                vfpStandardScore: standardScore + sin(Double(index) * 0.45) * 8
            )
        }
        let naturalnessWindows = (0..<12).map { index in
            PitcheeAnalysisResult.NaturalnessWindow(
                startSeconds: Double(index),
                endSeconds: Double(index + 1),
                score: naturalnessScore + cos(Double(index) * 0.35) * 7
            )
        }

        return PitcheeAnalysisResult(
            schemaVersion: 2,
            modelVersion: "debug-preview",
            audio: .init(sourceSampleRate: 44_100, sourceChannels: 1, inputSeconds: 12, analyzedSeconds: 12),
            vad: .init(
                segmentCount: segments.count,
                speechSeconds: 10,
                sileroSegmentCount: segments.count,
                discardedBreathLikeCount: 0,
                trimmedSegmentCount: 0,
                segments: segments
            ),
            f0: .init(
                windowSeconds: 0.5,
                meanHz: meanPitchHz,
                standardDeviationHz: 14,
                voicedFrameCount: 1_920,
                voicedWindowCount: pitchWindows.compactMap(\.f0Hz).count,
                windows: pitchWindows
            ),
            vfp: .init(
                vfpStandardScore: standardScore,
                windowCount: vfpWindows.count,
                windowDurationSeconds: 1,
                windows: vfpWindows
            ),
            naturalness: .init(
                score: naturalnessScore,
                windowCount: naturalnessWindows.count,
                windowDurationSeconds: 1,
                windows: naturalnessWindows
            ),
            composite: .init(
                baseScore: finalScore,
                finalScore: finalScore,
                cap: nil,
                rule: "continuous",
                limited: false,
                boosted: false
            )
        )
    }

    static let volumeStatistics: RecordingVolumeStatistics = {
        let windows = (0..<48).map { index in
            let isSpeech = index % 6 != 0
            let level = -28 + sin(Double(index) * 0.4) * 4
            return RecordingVolumeWindow(
                centerSeconds: Double(index) * 0.25 + 0.125,
                voiceDBFS: isSpeech ? level : nil,
                backgroundDBFS: isSpeech ? nil : level - 12
            )
        }
        return RecordingVolumeStatistics(
            environmentDBFS: -40,
            averageDBFS: -27,
            medianDBFS: -27,
            high95DBFS: -23,
            low5DBFS: -32,
            windows: windows
        )
    }()

    static let liveSamples: [LivePitchSample] = (0..<36).map { index in
        LivePitchSample(
            elapsedTime: Double(index) * 0.1,
            pitchHz: index % 9 == 0 ? nil : 175 + sin(Double(index) * 0.4) * 22
        )
    }
}

/// Owns a separate preferences suite and an in-memory store for each Canvas.
/// AppStorage changes, onboarding completion, and history never leak between
/// previews or into the app's normal data.
@MainActor
private final class DebugPreviewContext: ObservableObject {
    struct Environment {
        let container: ModelContainer
        let defaults: UserDefaults
    }

    let environment: Result<Environment, Error>
    private let suiteName = "com.lvyzhan.Pitchee.preview.\(UUID().uuidString)"

    init(withHistory: Bool, completedOnboarding: Bool) {
        do {
            guard let defaults = UserDefaults(suiteName: suiteName) else {
                throw CocoaError(.fileWriteUnknown)
            }
            defaults.register(defaults: [
                AppStorageKey.onboardingCompletedVersion: completedOnboarding ? OnboardingFlow.currentVersion : 0,
                AppStorageKey.voicePreference: VoicePreference.feminine.rawValue,
                AppStorageKey.openedDateKeys: withHistory ? "2026-9-24,2026-9-25,2026-9-26" : ""
            ])

            let container = try ModelContainer(
                for: RecordingAssessment.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            if withHistory {
                for (index, result) in DebugPreviewData.history.enumerated() {
                    let daysAgo = DebugPreviewData.history.count - index - 1
                    let assessment = try RecordingAssessment(
                        recordedAt: DebugPreviewData.recordedAt.addingTimeInterval(-Double(daysAgo) * 86_400),
                        result: result
                    )
                    container.mainContext.insert(assessment)
                }
                try container.mainContext.save()
            }
            environment = .success(Environment(container: container, defaults: defaults))
        } catch {
            environment = .failure(error)
        }
    }

    deinit {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }
}

@MainActor
struct DebugPreviewHost<Content: View>: View {
    @StateObject private var context: DebugPreviewContext
    private let content: () -> Content

    init(
        withHistory: Bool = false,
        completedOnboarding: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        _context = StateObject(wrappedValue: DebugPreviewContext(
            withHistory: withHistory,
            completedOnboarding: completedOnboarding
        ))
        self.content = content
    }

    var body: some View {
        switch context.environment {
        case .success(let environment):
            content()
                .modelContainer(environment.container)
                .defaultAppStorage(environment.defaults)
        case .failure(let error):
            VStack(spacing: 12) {
                Text(verbatim: "Preview setup failed")
                    .font(.headline)
                Text(verbatim: error.localizedDescription)
            }
            .padding()
        }
    }
}

/// Keeps the mock model alive when Canvas updates the surrounding view.
@MainActor
struct DebugAnalysisPreview<Content: View>: View {
    @StateObject private var viewModel: AnalysisViewModel
    private let content: (AnalysisViewModel) -> Content

    init(
        state: AnalysisViewModel.State,
        @ViewBuilder content: @escaping (AnalysisViewModel) -> Content
    ) {
        _viewModel = StateObject(wrappedValue: .preview(state: state))
        self.content = content
    }

    var body: some View {
        content(viewModel)
    }
}
#endif
