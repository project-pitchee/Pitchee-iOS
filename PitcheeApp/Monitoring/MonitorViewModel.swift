import AVFoundation
import Foundation
import Observation
import OSLog

enum MonitorKind: String, CaseIterable, Identifiable {
    case spectrum, pitch

    var id: String { rawValue }
    var titleKey: String { "monitor.\(rawValue).title" }
    var subtitleKey: String { "monitor.\(rawValue).subtitle" }
    var symbol: String { self == .spectrum ? "waveform.path" : "waveform.path.ecg" }
}

/// Each destination owns its microphone timeline. Playback freezes capture so
/// the speaker cannot feed back into the microphone or evict the selected audio.
@MainActor
@Observable
final class MonitorViewModel {
    enum State { case idle, preparing, live, paused, replaying }

    let kind: MonitorKind
    private(set) var state: State = .idle
    private(set) var errorMessage: String?
    private(set) var windowDuration: TimeInterval = 10
    private(set) var cursorTime: TimeInterval = 0
    private var timeline = MonitorTimeline()
    private var playbackRange: ClosedRange<TimeInterval>?

    @ObservationIgnored private var capture: MonitorAudioCapture?
    @ObservationIgnored private var analyzer: PitcheeCoreAnalyzer?
    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var playerDelegate: MonitorPlaybackDelegate?
    @ObservationIgnored private var operation: Task<Void, Never>?
    @ObservationIgnored private var playbackClock: Task<Void, Never>?
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var sessionOwner: UUID?
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private var sceneIsActive = true
    @ObservationIgnored private var awaitingPermission = false

    nonisolated private static let logger = Logger(subsystem: "com.lvyzhan.Pitchee", category: "Monitoring")

    init(kind: MonitorKind) {
        self.kind = kind
    }

    var statusKey: String {
        switch state {
        case .idle: "monitor.status.ready"
        case .preparing: "monitor.status.preparing"
        case .live: "monitor.status.live"
        case .paused: "monitor.status.paused"
        case .replaying: "monitor.status.replaying"
        }
    }

    var availableRange: ClosedRange<TimeInterval> { timeline.availableRange }
    var hasAudio: Bool { availableRange.upperBound > availableRange.lowerBound }
    var canRewind: Bool { !isBusy && cursorTime > availableRange.lowerBound }
    var isBusy: Bool { state == .preparing }

    var visibleRange: ClosedRange<TimeInterval> {
        if let playbackRange { return playbackRange }
        guard hasAudio else { return 0...windowDuration }
        let range = MonitorTimeline.window(
            endingAt: cursorTime, duration: windowDuration, availableRange: availableRange
        )
        // Give a cursor at the oldest retained sample a nonzero chart domain.
        return range.lowerBound...max(range.lowerBound + 0.001, range.upperBound)
    }

    var visiblePitchSamples: [LivePitchSample] {
        let range = visibleRange
        return timeline.pitchSamples.filter { range.contains($0.elapsedTime) }
    }

    var currentPitchHz: Double? {
        guard let sample = timeline.pitchSamples.last(where: { $0.elapsedTime <= cursorTime }),
              cursorTime - sample.elapsedTime <= 0.4 else { return nil }
        return sample.pitchHz
    }

    var currentSpectrum: MonitorSpectrumFrame? {
        guard let frame = timeline.spectrumFrames.last(where: { $0.elapsedTime <= cursorTime }),
              cursorTime - frame.elapsedTime <= 0.4 else { return nil }
        return frame
    }

    /// Frequency and amplitude readouts use the same strongest visible bin.
    var currentSpectrumPeak: (frequencyHz: Double, amplitudeDBFS: Float)? {
        guard let frame = currentSpectrum else { return nil }
        var peak: (frequencyHz: Double, amplitudeDBFS: Float)?
        for (index, magnitude) in frame.magnitudesDB.enumerated() {
            let frequency = Double(index) * frame.binWidthHz
            guard (40...8_000).contains(frequency), magnitude.isFinite,
                  magnitude > (peak?.amplitudeDBFS ?? -95) else { continue }
            peak = (frequency, magnitude)
        }
        return peak
    }

    var currentFrequencyHz: Double? {
        kind == .pitch ? currentPitchHz : currentSpectrumPeak?.frequencyHz
    }

    func startOrResume() {
        guard sceneIsActive, state != .live, !isBusy else { return }
        stopAudio()
        installObservers()
        errorMessage = nil
        cursorTime = timeline.duration
        state = .preparing
        let token = generation
        let owner = UUID()
        sessionOwner = owner
        awaitingPermission = true
        operation = Task { [weak self] in
            do {
                let granted = await withCheckedContinuation { continuation in
                    AVAudioApplication.requestRecordPermission { continuation.resume(returning: $0) }
                }
                guard let self, generation == token, !Task.isCancelled else { return }
                // Permission completion can arrive before the system dismisses
                // its prompt. Wait for the view's active event before opening
                // the microphone; background/leaving cancels this operation.
                while !sceneIsActive {
                    try await Task.sleep(for: .milliseconds(50))
                    guard generation == token else { return }
                }
                awaitingPermission = false
                guard granted else {
                    fail(String(localized: "recording.error.microphonePermissionDenied"))
                    return
                }

                var preparedAnalyzer: PitcheeCoreAnalyzer?
                if kind == .pitch {
                    if analyzer == nil {
                        let loaded = try await Task.detached(priority: .userInitiated) {
                            try PitcheeCoreAnalyzer()
                        }.value
                        guard generation == token, !Task.isCancelled else { return }
                        analyzer = loaded
                    }
                    preparedAnalyzer = analyzer
                    try await preparedAnalyzer?.resetRealtimeF0()
                }
                guard generation == token, !Task.isCancelled else { return }
                try await AudioSessionController.activate(owner: owner, use: .recording)
                guard generation == token, !Task.isCancelled else {
                    AudioSessionController.deactivate(owner: owner)
                    return
                }

                let offset = timeline.duration
                // Resuming starts a fresh detector context; don't connect the
                // previous voiced segment across an interval with no capture.
                timeline.appendPitch([LivePitchSample(elapsedTime: offset, pitchHz: nil)])
                let newCapture = MonitorAudioCapture()
                capture = newCapture
                try newCapture.start(analyzer: preparedAnalyzer, onUpdate: { [weak self] update in
                    await MainActor.run { [weak self] in
                        guard let self, generation == token, state == .live else { return }
                        append(update, offset: offset)
                    }
                }, onError: { [weak self] error in
                    Self.logger.error("Monitor capture failed: \(String(describing: error), privacy: .private)")
                    Task { @MainActor [weak self] in
                        guard let self, generation == token else { return }
                        fail(String(localized: "monitor.error.capture"))
                    }
                })
                state = .live
            } catch {
                AudioSessionController.deactivate(owner: owner)
                guard let self, generation == token, !Task.isCancelled else { return }
                Self.logger.error("Unable to start monitoring: \(String(describing: error), privacy: .private)")
                if error is AudioSessionCoordinator.Failure {
                    fail(String(localized: "monitor.error.sessionBusy"))
                } else {
                    fail(String(localized: "monitor.error.capture"))
                }
            }
        }
    }

    func pause() {
        if let player, let playbackRange {
            cursorTime = min(playbackRange.upperBound, playbackRange.lowerBound + player.currentTime)
        }
        let preserveReplaySelection = playbackRange != nil
            && (state == .preparing || state == .replaying)
        stopAudio(clearPlaybackRange: !preserveReplaySelection)
        state = hasAudio ? .paused : .idle
    }

    func seek(to time: TimeInterval) {
        guard sceneIsActive, hasAudio, !isBusy else { return }
        pause()
        playbackRange = nil
        cursorTime = MonitorTimeline.clampedTime(time, availableRange: availableRange)
    }

    func rewindFiveSeconds() {
        guard canRewind else { return }
        pause()
        playbackRange = nil
        cursorTime = MonitorTimeline.rewind(time: cursorTime, by: 5, availableRange: availableRange)
    }

    func setWindowDuration(_ seconds: TimeInterval) {
        guard [5.0, 10, 30].contains(seconds) else { return }
        if state == .replaying || state == .preparing { pause() }
        playbackRange = nil
        windowDuration = seconds
    }

    /// Toggles the compact transport's middle control. A paused replay keeps
    /// its original window so continuing starts at the current playhead rather
    /// than rebuilding the window from scratch.
    func toggleReplay() {
        guard sceneIsActive, hasAudio, !isBusy else { return }
        if state == .replaying {
            pause()
            return
        }
        if let playbackRange,
           state == .paused,
           cursorTime >= playbackRange.lowerBound,
           cursorTime < playbackRange.upperBound {
            beginPlayback(range: playbackRange, startingAt: cursorTime)
        } else {
            replayWindow()
        }
    }

    func replayWindow() {
        guard sceneIsActive, hasAudio, !isBusy else { return }
        pause()
        let range = MonitorTimeline.window(
            endingAt: cursorTime, duration: windowDuration, availableRange: availableRange
        )
        beginPlayback(range: range, startingAt: range.lowerBound)
    }

    private func beginPlayback(range: ClosedRange<TimeInterval>, startingAt: TimeInterval) {
        let samples = timeline.audio(in: range)
        guard !samples.isEmpty else {
            playbackRange = nil
            return
        }
        installObservers()
        errorMessage = nil
        let token = generation
        let owner = UUID()
        sessionOwner = owner
        state = .preparing
        playbackRange = range
        let initialTime = min(range.upperBound, max(range.lowerBound, startingAt))
        operation = Task { [weak self] in
            do {
                let data = await Task.detached(priority: .userInitiated) {
                    MonitorWaveEncoder.encode(samples)
                }.value
                try Task.checkCancellation()
                try await AudioSessionController.activate(owner: owner, use: .playback) { [weak self] in
                    self?.pause()
                }
                guard let self, generation == token, !Task.isCancelled else {
                    AudioSessionController.deactivate(owner: owner)
                    return
                }
                let audioPlayer = try AVAudioPlayer(data: data)
                let delegate = MonitorPlaybackDelegate { [weak self] successful in
                    guard let self, generation == token else { return }
                    if successful {
                        cursorTime = range.upperBound
                        stopAudio()
                        state = .paused
                    } else {
                        fail(String(localized: "monitor.error.playback"))
                    }
                }
                playerDelegate = delegate
                audioPlayer.delegate = delegate
                player = audioPlayer
                audioPlayer.currentTime = min(
                    audioPlayer.duration,
                    max(0, initialTime - range.lowerBound)
                )
                let played = await Task.detached(priority: .userInitiated) {
                    audioPlayer.play()
                }.value
                guard played else { throw CocoaError(.fileReadUnknown) }
                guard generation == token, !Task.isCancelled else {
                    audioPlayer.stop()
                    AudioSessionController.deactivate(owner: owner)
                    return
                }
                cursorTime = initialTime
                state = .replaying
                startPlaybackClock(token: token, range: range)
            } catch {
                AudioSessionController.deactivate(owner: owner)
                guard let self, generation == token, !Task.isCancelled else { return }
                fail(String(localized: error is AudioSessionCoordinator.Failure
                    ? "monitor.error.sessionBusy" : "monitor.error.playback"))
            }
        }
    }

    func handleSceneInactive() {
        // The system permission prompt also makes the scene inactive.
        sceneIsActive = false
        if !awaitingPermission { pause() }
    }

    func handleSceneActive() {
        sceneIsActive = true
    }

    func stopForLeaving() {
        pause()
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
        // Monitoring audio is ephemeral, never a saved recording.
        timeline = MonitorTimeline()
        cursorTime = 0
        playbackRange = nil
        analyzer = nil
        errorMessage = nil
        state = .idle
    }

    func clearError() { errorMessage = nil }

    private func append(_ update: MonitorCaptureUpdate, offset: TimeInterval) {
        timeline.appendAudio(update.samples)
        timeline.appendPitch(update.pitchFrames.map {
            LivePitchSample(elapsedTime: offset + $0.elapsedTime, pitchHz: $0.pitchHz)
        })
        timeline.appendSpectra(update.spectrumFrames.map {
            MonitorSpectrumFrame(elapsedTime: offset + $0.elapsedTime,
                                 magnitudesDB: $0.magnitudesDB, binWidthHz: $0.binWidthHz)
        })
        cursorTime = timeline.duration
    }

    private func startPlaybackClock(token: UUID, range: ClosedRange<TimeInterval>) {
        playbackClock = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(33)) } catch { return }
                guard let self, generation == token, state == .replaying, let player else { return }
                cursorTime = min(range.upperBound, range.lowerBound + player.currentTime)
            }
        }
    }

    private func stopAudio(clearPlaybackRange: Bool = true) {
        generation = UUID()
        awaitingPermission = false
        operation?.cancel()
        operation = nil
        playbackClock?.cancel()
        playbackClock = nil
        capture?.stop()
        capture = nil
        player?.stop()
        player = nil
        playerDelegate = nil
        if clearPlaybackRange { playbackRange = nil }
        if let sessionOwner { AudioSessionController.deactivate(owner: sessionOwner) }
        sessionOwner = nil
    }

    private func fail(_ message: String) {
        pause()
        errorMessage = message
    }

    private func installObservers() {
        guard observers.isEmpty else { return }
        for name in [AVAudioSession.interruptionNotification, AVAudioSession.routeChangeNotification,
                     AVAudioSession.mediaServicesWereResetNotification] {
            let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) {
                [weak self] notification in
                // A category change is part of our own capture/playback switch.
                if notification.name == AVAudioSession.routeChangeNotification {
                    let value = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
                    guard value == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue
                        || value == AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue else { return }
                }
                if notification.name == AVAudioSession.interruptionNotification {
                    let value = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
                    guard value == AVAudioSession.InterruptionType.began.rawValue else { return }
                }
                Task { @MainActor [weak self] in self?.pause() }
            }
            observers.append(observer)
        }
    }

    #if DEBUG
    /// Isolated fixtures for previews and the opt-in simulator review launch argument.
    /// No microphone, audio session, or persistent data is used.
    static func preview(kind: MonitorKind) -> MonitorViewModel {
        let model = MonitorViewModel(kind: kind)
        let sampleRate = MonitorTimeline.sampleRate
        let samples: [Float] = (0..<Int(sampleRate * 12)).map { index in
            let time = Double(index) / sampleRate
            return Float(sin(2 * .pi * 196 * time) * 0.16 + sin(2 * .pi * 392 * time) * 0.05)
        }
        model.timeline.appendAudio(samples)
        model.timeline.appendPitch((0...120).map { index in
            let time = Double(index) * 0.1
            let pitch = (42...49).contains(index) || (84...90).contains(index)
                ? nil : 196 + sin(time * 1.6) * 14 + sin(time * 4.1) * 3
            return LivePitchSample(elapsedTime: time, pitchHz: pitch)
        })
        let analyzer = try! MonitorSpectrumAnalyzer()
        model.timeline.appendSpectra(analyzer.process(samples))
        model.cursorTime = 11.9
        model.state = .paused
        return model
    }
    #endif
}

private final class MonitorPlaybackDelegate: NSObject, AVAudioPlayerDelegate {
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
