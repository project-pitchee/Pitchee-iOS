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
        case analyzing
        case completed
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var livePitchSamples: [LivePitchSample] = []
    @Published private(set) var result: PitcheeAnalysisResult?
    @Published private(set) var volumeStatistics: RecordingVolumeStatistics?
    @Published var errorMessage: String?

    private var audioCapture: LivePitchAudioCapture?
    private var recordingURL: URL?
    private var recordingStartedAt: Date?
    private var timerTask: Task<Void, Never>?
    private var analyzer: PitcheeCoreAnalyzer?
    private var analysisTask: Task<Void, Never>?
    private var permissionTask: Task<Void, Never>?
    private var recordedPitchSamples: [LivePitchSample] = []

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
            case .requestingPermission, .analyzing:
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
        case .requestingPermission, .analyzing:
            break
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func startRecording() {
        errorMessage = nil
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
                showError(String(localized: "recording.error.microphonePermissionDenied"))
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
            try await AudioSessionController.activate(category: .record, mode: .measurement)
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
                    Self.logger.error("Realtime F0 failed: \(String(describing: error), privacy: .public)")
                    self.errorMessage = String(localized: "recording.error.realtimePitchUnavailable")
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
            showError(recordingErrorMessage(for: error))
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
            Self.logger.error("Recording write failed: \(String(describing: writeError), privacy: .public)")
            if let recordingURL { try? FileManager.default.removeItem(at: recordingURL) }
            recordingURL = nil
            recordingStartedAt = nil
            showError(String(localized: "recording.error.saveFailed"))
            return
        }

        guard let recordingURL else {
            showError(String(localized: "recording.error.fileMissing"))
            return
        }

        let recordedAt = recordingStartedAt ?? Date()
        self.recordingURL = nil
        recordingStartedAt = nil
        state = .analyzing
        analyze(recordingURL, recordedAt: recordedAt, modelContext: modelContext)
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
        AudioSessionController.deactivate()
    }

    private func analyze(
        _ url: URL,
        recordedAt: Date,
        modelContext: ModelContext
    ) {
        analysisTask?.cancel()
        analysisTask = Task { [weak self] in
            guard let self else { return }

            do {
                let analyzer = try await preparedAnalyzer()

                let analysisResult = try await analyzer.analyze(wavFile: url)
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
                        "Volume analysis failed: \(String(describing: error), privacy: .public)"
                    )
                    volumeStatistics = nil
                }
                try? FileManager.default.removeItem(at: url)
                result = analysisResult
                self.volumeStatistics = volumeStatistics

                do {
                    let assessment = try RecordingAssessment(
                        recordedAt: recordedAt,
                        result: analysisResult
                    )
                    modelContext.insert(assessment)
                    do {
                        try modelContext.save()
                    } catch {
                        modelContext.delete(assessment)
                        throw error
                    }
                } catch {
                    errorMessage = String(localized: "analysis.error.resultSaveFailed")
                }
                state = .completed
            } catch {
                Self.logger.error("Analysis failed: \(String(describing: error), privacy: .public)")
                try? FileManager.default.removeItem(at: url)
                result = nil
                volumeStatistics = nil
                state = .idle
                showError(analysisErrorMessage(for: error))
            }
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

    private func showError(_ message: String) {
        errorMessage = message
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

    deinit {
        permissionTask?.cancel()
        timerTask?.cancel()
        analysisTask?.cancel()
        audioCapture?.stop()
        if let recordingURL { try? FileManager.default.removeItem(at: recordingURL) }
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
        errorMessage = nil
        switch state {
        case .idle, .requestingPermission:
            elapsedTime = 0
            livePitchSamples = []
        case .recording:
            elapsedTime = DebugPreviewData.liveSamples.last?.elapsedTime ?? 0
            livePitchSamples = DebugPreviewData.liveSamples
        case .analyzing, .completed:
            elapsedTime = DebugPreviewData.result.audio.inputSeconds
            livePitchSamples = DebugPreviewData.liveSamples
        }
        recordedPitchSamples = livePitchSamples
        result = state == .completed ? DebugPreviewData.result : nil
        volumeStatistics = state == .completed ? DebugPreviewData.volumeStatistics : nil
    }
}
#endif
