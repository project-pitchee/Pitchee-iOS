//
//  AudioSessionCoordinator.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/30.
//

import Foundation

/// A lease belongs to one activation attempt, not to a screen or a session category.
/// Late completion/cancellation of an old attempt must never stop its successor.
@MainActor
final class AudioSessionCoordinator {
    enum Use: Sendable { case recording, piano, playback }
    enum Failure: Error { case recordingInProgress, sessionBusy }

    private struct Lease {
        let owner: UUID
        let use: Use
        let stop: @MainActor () -> Void
    }

    private var lease: Lease?
    private let activateSession: (Use) async throws -> Void
    private let deactivateSession: () -> Void

    init(activate: @escaping (Use) async throws -> Void, deactivate: @escaping () -> Void) {
        activateSession = activate
        deactivateSession = deactivate
    }

    func activate(owner: UUID, use: Use, stopPlayback: @escaping @MainActor () -> Void) async throws {
        try Task.checkCancellation()
        if let previous = lease {
            guard previous.use != .recording else { throw Failure.recordingInProgress }
            previous.stop()
            guard lease == nil else { throw Failure.sessionBusy }
        }
        lease = Lease(owner: owner, use: use, stop: stopPlayback)
        do {
            try await activateSession(use)
            try Task.checkCancellation()
            guard lease?.owner == owner else { throw CancellationError() }
        } catch {
            release(owner: owner)
            throw error
        }
    }

    func release(owner: UUID) {
        guard lease?.owner == owner else { return }
        lease = nil
        // The backend enqueues this immediately, before any later activation.
        deactivateSession()
    }
}
