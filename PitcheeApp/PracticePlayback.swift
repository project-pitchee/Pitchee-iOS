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
final class PracticePlayback: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var playingID: UUID?
    @Published private(set) var error: String?
    private var player: AVAudioPlayer?
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
                try await AudioSessionController.activate(owner: owner, use: .playback) { [weak self] in
                    self?.stop()
                }
                guard let self, !Task.isCancelled, generation == token else { return }
                let player = try AVAudioPlayer(contentsOf: url)
                player.delegate = self
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
        playingID = nil
        if let sessionOwner { AudioSessionController.deactivate(owner: sessionOwner) }
        sessionOwner = nil
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            guard self?.player === player else { return }
            self?.stop()
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self] in
            guard self?.player === player else { return }
            self?.stop()
            self?.error = String(localized: "practice.playback.error")
        }
    }
}

struct PracticeTake: Identifiable {
    let id: UUID
    let result: PitcheeAnalysisResult
    let quality: RecordingQuality
    let url: URL
    var historySaved = false
}
