//
//  AudioSessionController.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/27.
//

import AVFoundation
import Foundation
import OSLog

/// Serializes changes to the shared session without blocking the main actor.
@MainActor
enum AudioSessionController {
    private static let queue = DispatchQueue(
        label: "com.lvyzhan.Pitchee.audio-session",
        qos: .userInitiated
    )
    private static let logger = Logger(subsystem: "com.lvyzhan.Pitchee", category: "AudioSession")

    static func activate(
        category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions = [],
        preferredIOBufferDuration: TimeInterval? = nil
    ) async throws {
        try Task.checkCancellation()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(category, mode: mode, options: options)
                    if let preferredIOBufferDuration {
                        try session.setPreferredIOBufferDuration(preferredIOBufferDuration)
                    }
                    // Keep configuration and activation together on this queue,
                    // including on OS versions without async activation APIs.
                    try session.setActive(true, options: [])
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    static func deactivate() {
        let logger = logger
        // Enqueue immediately so a subsequent activation cannot overtake cleanup.
        queue.async {
            do {
                try AVAudioSession.sharedInstance().setActive(
                    false,
                    options: .notifyOthersOnDeactivation
                )
            } catch {
                logger.error("Unable to deactivate audio session: \(String(describing: error), privacy: .public)")
            }
        }
    }
}
