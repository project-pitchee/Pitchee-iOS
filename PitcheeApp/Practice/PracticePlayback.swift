//
//  PracticePlayback.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/30.
//

import AVFoundation
import Combine
import Foundation

@MainActor
final class PracticePlayback: NSObject, ObservableObject {
    @Published private(set) var playingID: UUID?
    @Published private(set) var error: String?
    private var player: AVAudioPlayer?
    private var playerDelegate: PracticePlaybackDelegate?
    private var activation: Task<Void, Never>?
    private var generation = UUID()
    private var sessionOwner: UUID?

    func toggle(id: UUID, url: URL) {
        let wasPlaying = playingID == id
        stop()
        guard !wasPlaying else { return }
        error = nil
        let token = generation
        let owner = UUID()
        sessionOwner = owner
        playingID = id
        activation = Task { [weak self] in
            do {
                guard let self else { return }
                try await AudioSessionController.activate(owner: owner, use: .playback, holder: self) { [weak self] in
                    self?.stop()
                }
                guard !Task.isCancelled, generation == token else {
                    AudioSessionController.deactivate(owner: owner)
                    return
                }
                let player = try AVAudioPlayer(contentsOf: url)
                let delegate = PracticePlaybackDelegate { [weak self] successful in
                    guard let self, generation == token else { return }
                    stop()
                    if !successful { error = String(localized: "practice.playback.error") }
                }
                player.delegate = delegate
                playerDelegate = delegate
                self.player = player
                guard player.play() else { throw CocoaError(.fileReadUnknown) }
            } catch {
                AudioSessionController.deactivate(owner: owner)
                guard let self, generation == token else { return }
                stop()
                self.error = String(localized: "practice.playback.error")
            }
        }
    }

    func stop() {
        error = nil
        generation = UUID()
        activation?.cancel()
        activation = nil
        player?.stop()
        player = nil
        playerDelegate = nil
        playingID = nil
        if let sessionOwner { AudioSessionController.deactivate(owner: sessionOwner) }
        sessionOwner = nil
    }

    isolated deinit {
        activation?.cancel()
        player?.stop()
        if let sessionOwner { AudioSessionController.deactivate(owner: sessionOwner) }
    }
}

private final class PracticePlaybackDelegate: NSObject, AVAudioPlayerDelegate {
    let completion: @MainActor (Bool) -> Void

    init(completion: @escaping @MainActor (Bool) -> Void) {
        self.completion = completion
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in self?.completion(flag) }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self] in self?.completion(false) }
    }
}

struct PracticeTake: Identifiable {
    let id: UUID
    let result: PitcheeAnalysisResult
    let quality: RecordingQuality
    let url: URL
    var historySaved = false
}
