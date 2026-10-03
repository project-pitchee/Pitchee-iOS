//
//  AnalysisViewModel.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/13.
//

import AVFoundation
import Combine
import Foundation
import OSLog
import SwiftData

@MainActor
final class AnalysisViewModel: NSObject, ObservableObject {
    private static let logger = Logger(subsystem: "com.lvyzhan.Pitchee", category: "Analysis")
    enum State: Equatable {
        case idle
        case requestingPermission
        case recording
        case awaitingFeedback
        case analyzing
        case completed
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var livePitchSamples: [LivePitchSample] = []
    @Published private(set) var result: PitcheeAnalysisResult?
    @Published private(set) var volumeStatistics: RecordingVolumeStatistics?
    @Published private(set) var studyFeedbackDirection: ScoreStudyDirection?
    // Recording alerts and analysis feedback belong to separate screens.
    @Published private(set) var recordingError: String?
    @Published private(set) var analysisError: String?
    @Published private(set) var practice: PracticeContext?
    @Published private(set) var takes: [PracticeTake] = [] {
        didSet { retainedPracticeURLs = takes.map(\.url) }
    }
    @Published private(set) var assessment: RecordingAssessment?
    @Published private(set) var comparisonFeedback: PracticeFeedback?
    @Published private(set) var feedbackError: String?
    @Published private(set) var needsAudioCleanup = false
    let playback = PracticePlayback()

    var lastPracticeKind: PracticeKind? {
        UserDefaults.standard.string(forKey: "practice.lastKind").flatMap(PracticeKind.init(rawValue:))
    }
    var canConfigurePractice: Bool { state == .idle && takes.isEmpty }

    func selectPractice(_ kind: PracticeKind) {
        guard canConfigurePractice else { return }
        let target = VoicePreference(legacyStoredValue: UserDefaults.standard.string(forKey: AppStorageKey.voicePreference) ?? "") ?? .undecided
        practice = PracticeContext(kind: kind, target: target)
        UserDefaults.standard.set(kind.rawValue, forKey: "practice.lastKind")
    }

    @discardableResult
    func prepareRetake() -> Bool {
        guard state == .completed, !needsAudioCleanup else { return false }
        playback.stop()
        // A stays fixed; retry replaces B. Never keep a third audio file.
        if takes.count == 2 {
            guard removePracticeAudio([takes[1].url]) else { return false }
            takes.removeLast()
        }
        result = nil
        assessment = nil
        comparisonFeedback = nil
        feedbackError = nil
        volumeStatistics = nil
        elapsedTime = 0
        livePitchSamples = []
        recordedPitchSamples = []
        state = .idle
        return true
    }

    @discardableResult
    func endPractice() -> Bool {
        guard state == .idle || state == .completed else { return false }
        playback.stop()
        guard removePracticeAudio(takes.map(\.url)) else { return false }
        needsAudioCleanup = false
        takes = []
        practice = nil
        assessment = nil
        comparisonFeedback = nil
        feedbackError = nil
        result = nil
        volumeStatistics = nil
        elapsedTime = 0
        livePitchSamples = []
        recordedPitchSamples = []
        state = .idle
        return true
    }

    private func removePracticeAudio(_ urls: [URL]) -> Bool {
        do {
            for url in urls {
                do { try FileManager.default.removeItem(at: url) }
                catch let error as CocoaError where error.code == .fileNoSuchFile { continue }
            }
            return true
        } catch {
            needsAudioCleanup = true
            let message = String(localized: "practice.audio.cleanupError")
            if state == .idle { recordingError = message }
            else { analysisError = message }
            return false
        }
    }

    func saveComparisonFeedback(_ feedback: PracticeFeedback, modelContext: ModelContext) {
        guard takes.count == 2, let assessment, assessment.modelContext != nil,
              assessment.comparedToID != nil else {
            feedbackError = String(localized: "practice.feedback.saveError")
            return
        }
        let previous = assessment.comparisonFeedbackRawValue
        assessment.comparisonFeedbackRawValue = feedback.rawValue
        do {
            try modelContext.save()
            comparisonFeedback = feedback
            feedbackError = nil
        } catch {
            assessment.comparisonFeedbackRawValue = previous
            feedbackError = String(localized: "practice.feedback.saveError")
        }
    }

    /// Do not silently resume a partial utterance after an interruption or a
    /// route change. The user restarts the same passage; completed takes survive.
    func interruptCapture() {
        playback.stop()
        guard state == .recording || state == .requestingPermission else { return }
        permissionTask?.cancel()
        stopTimer()
        audioCapture?.stop()
        audioCapture = nil
        if let recordingURL { try? FileManager.default.removeItem(at: recordingURL) }
        recordingURL = nil
        recordingStartedAt = nil
        recordingStudyAuthorization = nil
        recordingStudyDirection = nil
        deactivateAudioSession()
        showRecordingError(String(localized: "practice.recording.interrupted"))
    }

    // Deinitialization can read these Sendable URLs without accessing the
    // main-actor-isolated Published getter for the practice UI state.
    private var retainedPracticeURLs: [URL] = []
    private var audioCapture: LivePitchAudioCapture?
    private var recordingURL: URL?
    private var recordingStartedAt: Date?
    private var timerTask: Task<Void, Never>?
    private var analyzer: PitcheeCoreAnalyzer?
    private var analysisTask: Task<Void, Never>?
    private var permissionTask: Task<Void, Never>?
    private var recordedPitchSamples: [LivePitchSample] = []
    private let audioSessionOwner = UUID()
    private var recordingStudyAuthorization: LocalScoreStudyStore.Authorization?
    private var recordingStudyDirection: ScoreStudyDirection?
    private var feedbackTimeoutTask: Task<Void, Never>?
    private var pendingStudy: PendingStudy?

    private struct PendingStudy {
        let url: URL
        let recordedAt: Date
        let modelContext: ModelContext
        let attempt: LocalScoreStudyStore.Attempt
    }

    #if DEBUG
    private var usesPreviewData = false
    #endif

    var pitchTimeline: PitchTimeline {
        if let result { return PitchTimeline(result: result) }
        return PitchTimeline(samples: recordedPitchSamples, duration: elapsedTime)
    }

    var isRequestingPermission: Bool {
        state == .requestingPermission
    }

    var isRecording: Bool {
        state == .recording
    }

    var isAnalyzing: Bool {
        state == .analyzing
    }

    var isAwaitingFeedback: Bool { state == .awaitingFeedback }
    var needsAnalysisScreen: Bool { isAnalyzing || isAwaitingFeedback }

    /// Compatibility surface for the original recording and result screens.
    /// Newer flows keep recording and analysis errors separate internally, but
    /// the original UI intentionally presents one alert at a time.
    var errorMessage: String? { recordingError ?? analysisError }

    func clearError() {
        recordingError = nil
        analysisError = nil
    }

    var hasResult: Bool {
        result != nil && state == .completed
    }

    func primaryButtonTapped(modelContext: ModelContext) {
        #if DEBUG
        if usesPreviewData {
            switch state {
            case .idle, .completed:
                applyPreviewState(.recording)
            case .recording:
                applyPreviewState(.completed)
            case .requestingPermission, .awaitingFeedback, .analyzing:
                break
            }
            return
        }
        #endif

        switch state {
        case .recording:
            stopRecording(modelContext: modelContext)
        case .idle, .completed:
            startRecording()
        case .requestingPermission, .awaitingFeedback, .analyzing:
            break
        }
    }

    func clearRecordingError() {
        recordingError = nil
    }

    private func startRecording() {
        guard !needsAudioCleanup else {
            recordingError = String(localized: "practice.audio.cleanupError")
            return
        }
        if state == .completed, !prepareRetake() { return }
        if practice == nil { selectPractice(.dailyReading) }
        playback.stop()
        recordingStudyAuthorization = LocalScoreStudyStore.shared.authorizeRecording()
        let preference = practice?.target ?? .undecided
        recordingStudyDirection = ScoreStudyEvaluator.direction(for: preference)
        recordingError = nil
        analysisError = nil
        result = nil
        elapsedTime = 0
        livePitchSamples = []
        recordedPitchSamples = []
        volumeStatistics = nil
        recordingStartedAt = nil
        state = .requestingPermission

        permissionTask = Task { [weak self] in
            guard let self else { return }
            let granted = await requestMicrophonePermission()
            guard !Task.isCancelled else { return }

            if granted {
                await beginRecording()
            } else {
                showRecordingError(String(localized: "recording.error.microphonePermissionDenied"))
            }
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func beginRecording() async {
        guard state == .requestingPermission else { return }

        do {
            let analyzer = try await preparedAnalyzer()
            try await analyzer.resetRealtimeF0()
            guard !Task.isCancelled, state == .requestingPermission else { return }
            try await AudioSessionController.activate(
                owner: audioSessionOwner,
                use: .recording,
                stopPlayback: { [weak self] in self?.playback.stop() }
            )
            guard !Task.isCancelled, state == .requestingPermission else {
                deactivateAudioSession()
                return
            }

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("pitchee-\(UUID().uuidString)")
                .appendingPathExtension("wav")
            let newCapture = LivePitchAudioCapture()
            recordingURL = url
            try newCapture.start(writingTo: url, analyzer: analyzer, onPitch: { [weak self] frames in
                Task { @MainActor [weak self] in
                    guard let self,
                          self.state == .recording,
                          self.recordingURL == url else { return }
                    self.appendLivePitch(frames)
                }
            }, onError: { [weak self] error in
                Task { @MainActor [weak self] in
                    guard let self, self.state == .recording, self.recordingURL == url else { return }
                    Self.logger.error("Realtime F0 failed: \(String(describing: error), privacy: .private)")
                    self.recordingError = String(localized: "recording.error.realtimePitchUnavailable")
                }
            })

            audioCapture = newCapture
            recordingURL = url
            recordingStartedAt = Date()
            state = .recording
            startTimer()
        } catch {
            if let recordingURL { try? FileManager.default.removeItem(at: recordingURL) }
            recordingURL = nil
            deactivateAudioSession()
            showRecordingError(recordingErrorMessage(for: error))
        }
    }

    private func stopRecording(modelContext: ModelContext) {
        guard state == .recording, let audioCapture else { return }

        stopTimer()
        if let recordingStartedAt { elapsedTime = Date().timeIntervalSince(recordingStartedAt) }
        let writeError = audioCapture.stop()
        self.audioCapture = nil
        deactivateAudioSession()

        if let writeError {
            Self.logger.error("Recording write failed: \(String(describing: writeError), privacy: .private)")
            if let recordingURL { try? FileManager.default.removeItem(at: recordingURL) }
            recordingURL = nil
            recordingStartedAt = nil
            showRecordingError(String(localized: "recording.error.saveFailed"))
            return
        }

        guard let recordingURL else {
            showRecordingError(String(localized: "recording.error.fileMissing"))
            return
        }

        let recordedAt = recordingStartedAt ?? Date()
        self.recordingURL = nil
        recordingStartedAt = nil
        clearRecordingError()
        let invitation = LocalScoreStudyStore.shared.invite(
            authorizedBy: recordingStudyAuthorization, direction: recordingStudyDirection
        )
        recordingStudyAuthorization = nil
        recordingStudyDirection = nil
        if let invitation {
            pendingStudy = PendingStudy(url: recordingURL, recordedAt: recordedAt,
                                        modelContext: modelContext, attempt: invitation)
            studyFeedbackDirection = invitation.direction
            state = .awaitingFeedback
            feedbackTimeoutTask = Task { [weak self] in
                do { try await Task.sleep(for: .seconds(LocalScoreStudyState.feedbackSeconds)) } catch { return }
                self?.submitStudyFeedback(.timedOut)
            }
            return
        }
        state = .analyzing
        analyze(recordingURL, recordedAt: recordedAt, modelContext: modelContext)
    }

    func submitStudyFeedback(_ feedback: ScoreStudyFeedback) {
        #if DEBUG
        if usesPreviewData, isAwaitingFeedback {
            studyFeedbackDirection = nil
            applyPreviewState(.completed)
            return
        }
        #endif
        guard let pendingStudy else { return }
        self.pendingStudy = nil
        feedbackTimeoutTask?.cancel()
        feedbackTimeoutTask = nil
        studyFeedbackDirection = nil
        LocalScoreStudyStore.shared.respond(pendingStudy.attempt, feedback: feedback)
        state = .analyzing
        analyze(pendingStudy.url, recordedAt: pendingStudy.recordedAt,
                modelContext: pendingStudy.modelContext, studyAttempt: pendingStudy.attempt)
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000)
                guard let self,
                      self.state == .recording,
                      let recordingStartedAt = self.recordingStartedAt else { return }
                elapsedTime = Date().timeIntervalSince(recordingStartedAt)
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func appendLivePitch(_ frames: [PitcheeF0Frame]) {
        let samples = frames.map { LivePitchSample(elapsedTime: $0.elapsedTime, pitchHz: $0.pitchHz) }
        recordedPitchSamples.append(contentsOf: samples)
        livePitchSamples.append(contentsOf: samples)

        let oldestVisibleTime = max(0, (samples.last?.elapsedTime ?? 0) - PitchTimeline.visibleSeconds)
        if let firstVisibleIndex = livePitchSamples.firstIndex(where: {
            $0.elapsedTime >= oldestVisibleTime
        }), firstVisibleIndex > 1 {
            livePitchSamples.removeFirst(firstVisibleIndex - 1)
        }
    }

    private func deactivateAudioSession() {
        AudioSessionController.deactivate(owner: audioSessionOwner)
    }

    private func analyze(
        _ url: URL,
        recordedAt: Date,
        modelContext: ModelContext,
        studyAttempt: LocalScoreStudyStore.Attempt? = nil
    ) {
        analysisTask?.cancel()
        let practiceSnapshot = practice
        let previousID = takes.first.flatMap { $0.historySaved ? $0.id : nil }
        let diagnostics = LocalDiagnosticsStore.shared
        let diagnosticToken = diagnostics.beginAttempt()
        let recordedSeconds = elapsedTime
        let startedAt = ProcessInfo.processInfo.systemUptime
        analysisTask = Task { [weak self] in
            var diagnosticOutcome = DiagnosticOutcome.interrupted
            var inputSeconds: Double? = recordedSeconds
            var speechSeconds: Double?
            var quality = DiagnosticQuality.unavailable
            var studyPair: ScoreStudyPair?
            var studyFailed = true
            var retainedForPractice = false
            defer {
                if !retainedForPractice { try? FileManager.default.removeItem(at: url) }
                LocalScoreStudyStore.shared.finish(studyAttempt, pair: studyPair, failed: studyFailed)
                diagnostics.finish(diagnosticToken, outcome: diagnosticOutcome, observation: .init(
                    inputSeconds: inputSeconds, speechSeconds: speechSeconds, quality: quality,
                    latencySeconds: ProcessInfo.processInfo.systemUptime - startedAt
                ))
            }
            guard let self else { diagnosticOutcome = .cancelled; return }

            do {
                try Task.checkCancellation()
                let analyzer = try await preparedAnalyzer()

                let analysisResult = try await analyzer.analyze(wavFile: url)
                try Task.checkCancellation()
                if let studyAttempt {
                    studyPair = ScoreStudyEvaluator.pair(for: analysisResult, direction: studyAttempt.direction)
                }
                inputSeconds = analysisResult.audio.inputSeconds
                speechSeconds = analysisResult.vad.speechSeconds
                let volumeStatistics: RecordingVolumeStatistics?
                do {
                    volumeStatistics = try await Task.detached(priority: .userInitiated) {
                        try RecordingVolumeAnalyzer.analyze(
                            wavFile: url,
                            speechSegments: analysisResult.vad.segments
                        )
                    }.value
                } catch {
                    Self.logger.error(
                        "Volume analysis failed: \(String(describing: error), privacy: .private)"
                    )
                    volumeStatistics = nil
                }
                try Task.checkCancellation()
                if diagnosticToken != nil, let volumeStatistics {
                    // Only actual non-speech windows count as background. The UI's
                    // quietest-voice fallback would imply a nonexistent noise reference.
                    let background = volumeStatistics.windows.compactMap(\.backgroundDBFS).sorted()
                    quality = DiagnosticQuality(
                        speechDBFS: volumeStatistics.medianDBFS,
                        backgroundDBFS: RecordingStatisticsMath.percentile(0.5, in: background)
                    )
                }
                result = analysisResult
                self.volumeStatistics = volumeStatistics
                let recordingQuality = RecordingQuality(
                    speechSeconds: analysisResult.vad.speechSeconds,
                    speechDBFS: volumeStatistics?.medianDBFS,
                    backgroundDBFS: volumeStatistics?.measuredBackgroundDBFS,
                    clippedFraction: volumeStatistics?.clippedSampleFraction
                )
                let assessmentID = UUID()
                if practiceSnapshot != nil {
                    takes.append(PracticeTake(id: assessmentID, result: analysisResult, quality: recordingQuality, url: url))
                    retainedForPractice = true
                }
                diagnosticOutcome = .success
                studyFailed = false

                do {
                    let assessment = try RecordingAssessment(
                        id: assessmentID,
                        recordedAt: recordedAt,
                        result: analysisResult,
                        practice: practiceSnapshot,
                        quality: recordingQuality,
                        comparedToID: previousID
                    )
                    self.assessment = assessment
                    modelContext.insert(assessment)
                    do {
                        try modelContext.save()
                        if let index = takes.firstIndex(where: { $0.id == assessmentID }) {
                            takes[index].historySaved = true
                        }
                    } catch {
                        modelContext.delete(assessment)
                        throw error
                    }
                } catch {
                    diagnosticOutcome = .historySaveFailed
                    analysisError = String(localized: "analysis.error.resultSaveFailed")
                }
                state = .completed
            } catch {
                diagnosticOutcome = Self.diagnosticOutcome(for: error)
                Self.logger.error("Analysis failed: \(String(describing: error), privacy: .private)")
                result = nil
                volumeStatistics = nil
                state = .idle
                if !(error is CancellationError) { analysisError = analysisErrorMessage(for: error) }
            }
        }
    }

    private static func diagnosticOutcome(for error: Error) -> DiagnosticOutcome {
        if error is CancellationError { return .cancelled }
        guard let error = error as? PitcheeCoreError else { return .analysisFailed }
        switch error.statusCode {
        case 5: return .noSpeech
        case 2, 6: return .unreadableAudio
        case 3, 4: return .modelUnavailable
        default: return .analysisFailed
        }
    }

    private func preparedAnalyzer() async throws -> PitcheeCoreAnalyzer {
        if let analyzer { return analyzer }
        let analyzer = try await Task.detached(priority: .userInitiated) {
            try PitcheeCoreAnalyzer()
        }.value
        self.analyzer = analyzer
        return analyzer
    }

    private func showRecordingError(_ message: String) {
        recordingError = message
        if state != .analyzing {
            state = .idle
        }
    }

    private func recordingErrorMessage(for error: Error) -> String {
        if error is PitcheeCoreError {
            return analysisErrorMessage(for: error)
        }
        if error is LivePitchAudioCaptureError {
            return String(localized: "recording.error.microphoneUnavailable")
        }
        return String(localized: "recording.error.startFailed")
    }

    private func analysisErrorMessage(for error: Error) -> String {
        guard let coreError = error as? PitcheeCoreError else {
            return String(localized: "analysis.error.resultUnreadable")
        }

        switch coreError.statusCode {
        case 5: // PITCHEE_ERROR_NO_SPEECH
            return String(localized: "analysis.error.noSpeechDetected")
        case 3, 4: // PITCHEE_ERROR_ORT_UNAVAILABLE, PITCHEE_ERROR_MODEL
            return String(localized: "analysis.error.modelUnavailable \(coreError.statusCode)")
        case 2, 6: // PITCHEE_ERROR_IO, PITCHEE_ERROR_UNSUPPORTED_FORMAT
            return String(localized: "analysis.error.recordingUnreadable \(coreError.statusCode)")
        default:
            return String(localized: "analysis.error.analysisFailed \(coreError.statusCode)")
        }
    }

    isolated deinit {
        playback.stop()
        permissionTask?.cancel()
        timerTask?.cancel()
        analysisTask?.cancel()
        feedbackTimeoutTask?.cancel()
        audioCapture?.stop()
        if let recordingURL { try? FileManager.default.removeItem(at: recordingURL) }
        if let pendingStudy { try? FileManager.default.removeItem(at: pendingStudy.url) }
        for url in retainedPracticeURLs { try? FileManager.default.removeItem(at: url) }
    }
}

#if DEBUG
extension AnalysisViewModel {
    /// Supplies real UI states without requesting microphone permission,
    /// loading inference models, starting timers, or saving assessments.
    static func preview(state: State = .idle) -> AnalysisViewModel {
        let model = AnalysisViewModel()
        model.usesPreviewData = true
        model.applyPreviewState(state)
        return model
    }

    private func applyPreviewState(_ state: State) {
        self.state = state
        recordingError = nil
        analysisError = nil
        switch state {
        case .idle, .requestingPermission:
            elapsedTime = 0
            livePitchSamples = []
        case .recording:
            elapsedTime = DebugPreviewData.liveSamples.last?.elapsedTime ?? 0
            livePitchSamples = DebugPreviewData.liveSamples
        case .awaitingFeedback, .analyzing, .completed:
            elapsedTime = DebugPreviewData.result.audio.inputSeconds
            livePitchSamples = DebugPreviewData.liveSamples
        }
        recordedPitchSamples = livePitchSamples
        result = state == .completed ? DebugPreviewData.result : nil
        volumeStatistics = state == .completed ? DebugPreviewData.volumeStatistics : nil
        studyFeedbackDirection = state == .awaitingFeedback ? .feminine : nil
    }
}
#endif
