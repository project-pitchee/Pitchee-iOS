//
//  PracticeCaptions.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/30.
//

import Combine
import Foundation
import Speech

/// Captions are transient, like the practice recordings. Recognition is never
/// allowed to fall back to a server, even when the local model is unavailable.
@MainActor
final class PracticeCaptions: ObservableObject {
    @Published private(set) var transcripts: [UUID: String] = [:]
    @Published private(set) var activeID: UUID?
    @Published private(set) var error: String?

    private var recognizer: SFSpeechRecognizer?
    private var recognition: SFSpeechRecognitionTask?
    private var preparation: Task<Void, Never>?
    private var generation = UUID()

    func generate(id: UUID, url: URL) {
        cancel()
        error = nil
        activeID = id
        let token = generation
        preparation = Task { [weak self] in
            guard let self, !Task.isCancelled, self.generation == token else { return }
            guard let recognizer = SFSpeechRecognizer(locale: .current),
                  recognizer.supportsOnDeviceRecognition else {
                fail(String(localized: "practice.captions.unavailable"), token: token)
                return
            }
            let authorization = await Self.authorization()
            guard !Task.isCancelled, generation == token else { return }
            guard authorization == .authorized else {
                fail(String(localized: "practice.captions.permission"), token: token)
                return
            }
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.requiresOnDeviceRecognition = true
            request.shouldReportPartialResults = false
            self.recognizer = recognizer
            recognition = recognizer.recognitionTask(with: request) { [weak self] result, error in
                let caption = result?.isFinal == true ? result?.bestTranscription.formattedString : nil
                let failed = error != nil
                Task { @MainActor [weak self] in
                    guard let self, generation == token else { return }
                    if let caption, !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        transcripts[id] = caption
                        cancel()
                    } else if failed || caption != nil {
                        fail(String(localized: "practice.captions.failed"), token: token)
                    }
                }
            }
        }
    }

    func cancel() {
        generation = UUID()
        preparation?.cancel()
        preparation = nil
        recognition?.cancel()
        recognition = nil
        recognizer = nil
        activeID = nil
    }

    func clear() {
        cancel()
        transcripts = [:]
        error = nil
    }

    private func fail(_ message: String, token: UUID) {
        guard generation == token else { return }
        cancel()
        error = message
    }

    private static func authorization() async -> SFSpeechRecognizerAuthorizationStatus {
        let status = SFSpeechRecognizer.authorizationStatus()
        guard status == .notDetermined else { return status }
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
    }
}
