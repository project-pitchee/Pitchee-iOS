//
//  AnalysisViewModel.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/13.
//

import AVFoundation
import Combine
import Foundation

@MainActor
final class AnalysisViewModel: NSObject, ObservableObject {
    enum State: Equatable {
        case idle
        case recording
        case analyzing
        case completed
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var result: PitcheeAnalysisResult?
    @Published var errorMessage: String?

    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var timerTask: Task<Void, Never>?
    private var analyzer: PitcheeCoreAnalyzer?
    private var analysisTask: Task<Void, Never>?

    var isRecording: Bool {
        state == .recording
    }

    var isAnalyzing: Bool {
        state == .analyzing
    }

    var hasResult: Bool {
        result != nil && state == .completed
    }

    func primaryButtonTapped() {
        switch state {
        case .recording:
            stopRecording()
        case .idle, .completed:
            startRecording()
        case .analyzing:
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

        Task { [weak self] in
            guard let self else { return }
            let granted = await requestMicrophonePermission()
            guard !Task.isCancelled else { return }

            if granted {
                beginRecording()
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

    private func beginRecording() {
        guard state != .analyzing else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("pitchee-\(UUID().uuidString)")
                .appendingPathExtension("wav")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ]

            let newRecorder = try AVAudioRecorder(url: url, settings: settings)
            newRecorder.isMeteringEnabled = true
            guard newRecorder.prepareToRecord(), newRecorder.record() else {
                throw RecordingError.couldNotStart
            }

            recorder = newRecorder
            recordingURL = url
            state = .recording
            startTimer()
        } catch {
            deactivateAudioSession()
            showError(recordingErrorMessage(for: error))
        }
    }

    private func stopRecording() {
        guard state == .recording, let recorder else { return }

        stopTimer()
        recorder.stop()
        self.recorder = nil
        deactivateAudioSession()

        guard let recordingURL else {
            showError("录音文件没有生成，请再试一次。")
            return
        }

        self.recordingURL = nil
        state = .analyzing
        analyze(recordingURL)
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000)
                guard let self, let recorder = self.recorder else { return }
                elapsedTime = recorder.currentTime
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }

    private func analyze(_ url: URL) {
        analysisTask?.cancel()
        analysisTask = Task { [weak self] in
            guard let self else { return }

            do {
                let analyzer: PitcheeCoreAnalyzer
                if let existingAnalyzer = self.analyzer {
                    analyzer = existingAnalyzer
                } else {
                    let newAnalyzer = try PitcheeCoreAnalyzer()
                    self.analyzer = newAnalyzer
                    analyzer = newAnalyzer
                }

                let analysisResult = try await analyzer.analyze(wavFile: url)
                try? FileManager.default.removeItem(at: url)
                result = analysisResult
                state = .completed
            } catch {
                try? FileManager.default.removeItem(at: url)
                result = nil
                state = .idle
                showError(analysisErrorMessage(for: error))
            }
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        if state != .analyzing {
            state = .idle
        }
    }

    private func recordingErrorMessage(for error: Error) -> String {
        if let recordingError = error as? RecordingError,
           recordingError == .couldNotStart {
            return "无法开始录音，请检查麦克风是否可用。"
        }
        return "无法开始录音，请稍后再试。"
    }

    private func analysisErrorMessage(for error: Error) -> String {
        guard let coreError = error as? PitcheeCoreError else {
            return "分析失败，请稍后再试。"
        }

        switch coreError.statusCode {
        case 5: // PITCHEE_ERROR_NO_SPEECH
            return "没有检测到人声，请录一段更清晰、包含连续说话的音频。"
        case 3, 4: // PITCHEE_ERROR_ORT_UNAVAILABLE, PITCHEE_ERROR_MODEL
            return "分析模型暂时不可用，请重启应用后再试。"
        default:
            return "分析失败，请再录一段音频试试。"
        }
    }

    deinit {
        timerTask?.cancel()
        analysisTask?.cancel()
        recorder?.stop()
    }
}

private enum RecordingError: Error {
    case couldNotStart
}
