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
    @Published private(set) var inputLevel: Double = 0
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
        inputLevel = 0
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
                showError("请在系统设置中允许 Pitchee 使用麦克风，然后再试一次。")
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
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

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
            }, onLevel: { [weak self] level in
                Task { @MainActor [weak self] in
                    guard let self, self.state == .recording, self.recordingURL == url else { return }
                    self.inputLevel = level
                }
            }, onError: { [weak self] error in
                Task { @MainActor [weak self] in
                    guard let self, self.state == .recording, self.recordingURL == url else { return }
                    Self.logger.error("Realtime F0 failed: \(String(describing: error), privacy: .public)")
                    self.errorMessage = "实时音高暂时不可用，录音仍在继续，结束后将进行完整分析。"
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
        inputLevel = 0
        deactivateAudioSession()

        if let writeError {
            Self.logger.error("Recording write failed: \(String(describing: writeError), privacy: .public)")
            if let recordingURL { try? FileManager.default.removeItem(at: recordingURL) }
            recordingURL = nil
            recordingStartedAt = nil
            showError("录音未能保存，请检查设备存储空间后重试。")
            return
        }

        guard let recordingURL else {
            showError("录音文件没有生成，请再试一次。")
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
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
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
                    errorMessage = "测评已完成，但结果未能保存。请检查设备存储空间后再试。"
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
            return "无法开始录音，请检查麦克风是否可用。"
        }
        return "无法开始录音，请稍后再试。"
    }

    private func analysisErrorMessage(for error: Error) -> String {
        guard let coreError = error as? PitcheeCoreError else {
            return "分析结果无法读取（E-JSON），请稍后再试。"
        }

        switch coreError.statusCode {
        case 5: // PITCHEE_ERROR_NO_SPEECH
            return "没有检测到人声，请录一段更清晰、包含连续说话的音频。"
        case 3, 4: // PITCHEE_ERROR_ORT_UNAVAILABLE, PITCHEE_ERROR_MODEL
            return "分析模型暂时不可用（E-\(coreError.statusCode)），请重启应用后再试。"
        case 2, 6: // PITCHEE_ERROR_IO, PITCHEE_ERROR_UNSUPPORTED_FORMAT
            return "录音格式无法读取（E-\(coreError.statusCode)），请重新录制。"
        default:
            return "分析失败（E-\(coreError.statusCode)），请再录一段音频试试。"
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
