import AVFoundation
import Foundation

// Platform/inference substitutes for compiling the production view model on
// macOS. Production state transitions, persistence and playback are unchanged.
enum AVAudioApplication {
    static var permission: (@Sendable (Bool) -> Void)?
    static func requestRecordPermission(_ response: @escaping @Sendable (Bool) -> Void) {
        permission = response
    }
    static func respond(_ granted: Bool) {
        let response = permission
        permission = nil
        response?(granted)
    }
}

nonisolated enum AVAudioSession {
    static let interruptionNotification = Notification.Name("test.audio.interruption")
    static let routeChangeNotification = Notification.Name("test.audio.route")
    static let mediaServicesWereResetNotification = Notification.Name("test.audio.reset")
    enum InterruptionType: UInt { case began = 1, ended = 0 }
    enum RouteChangeReason: UInt {
        case newDeviceAvailable = 1, oldDeviceUnavailable = 2, categoryChange = 3
        case noSuitableRouteForCategory = 7
    }
}
nonisolated let AVAudioSessionInterruptionTypeKey = "type"
nonisolated let AVAudioSessionRouteChangeReasonKey = "reason"

enum AudioSessionController {
    static var gate: LifecycleAsyncGate?
    static var shouldFail = false
    static let coordinator = makeCoordinator()
    private static func makeCoordinator() -> AudioSessionCoordinator {
        AudioSessionCoordinator(
            activate: { _ in
                if let gate {
                    CaptureFixture.shared.record("activationWaiting")
                    await gate.wait()
                }
                if shouldFail { throw CocoaError(.fileReadUnknown) }
                CaptureFixture.shared.record("activate")
            },
            deactivate: { CaptureFixture.shared.record("deactivate") }
        )
    }
    static func activate(owner: UUID, use: AudioSessionCoordinator.Use, holder: AnyObject,
                         stopPlayback: @escaping @MainActor () -> Void = {}) async throws {
        try await coordinator.activate(owner: owner, use: use, holder: holder, stopPlayback: stopPlayback)
    }
    static func deactivate(owner: UUID) { coordinator.release(owner: owner) }
    static func retainUntilStopped(owner: UUID, holder: AnyObject) {
        coordinator.retainUntilStopped(owner: owner, holder: holder)
    }
}

nonisolated final class LifecycleAsyncGate: @unchecked Sendable {
    private let lock = NSLock()
    private var isOpen = false
    private var continuations: [CheckedContinuation<Void, Never>] = []
    func wait() async {
        await withCheckedContinuation { continuation in
            let ready = lock.withLock {
                if isOpen { return true }
                continuations.append(continuation)
                return false
            }
            if ready { continuation.resume() }
        }
    }
    func open() {
        let pending = lock.withLock {
            isOpen = true
            let pending = continuations
            continuations = []
            return pending
        }
        pending.forEach { $0.resume() }
    }
}

nonisolated final class CaptureFixture: @unchecked Sendable {
    static let shared = CaptureFixture()
    private let lock = NSLock()
    private var events: [String] = []
    private var url: URL?
    private var handler: (@Sendable (Error) -> Void)?
    private var blockedStart: DispatchSemaphore?
    private var blockedFinish: LifecycleAsyncGate?
    private var failedFinish = false

    func reset(start: DispatchSemaphore? = nil, finish: LifecycleAsyncGate? = nil, failFinish: Bool = false) {
        lock.withLock {
            events = []
            url = nil
            handler = nil
            blockedStart = start
            blockedFinish = finish
            failedFinish = failFinish
        }
    }
    func record(_ event: String) { lock.withLock { events.append(event) } }
    func count(_ event: String) -> Int { lock.withLock { events.filter { $0 == event }.count } }
    var lastURL: URL? { lock.withLock { url } }
    var finishGate: LifecycleAsyncGate? { lock.withLock { blockedFinish } }
    var finishFails: Bool { lock.withLock { failedFinish } }
    func started(url: URL, handler: (@Sendable (Error) -> Void)?) {
        let gate = lock.withLock {
            self.url = url
            self.handler = handler
            events.append("start")
            return blockedStart
        }
        if let gate { precondition(gate.wait(timeout: .now() + 10) == .success) }
    }
    func failWrite() { lock.withLock { handler }?(CocoaError(.fileWriteOutOfSpace)) }
}

nonisolated enum LivePitchAudioCaptureError: Error { case inputUnavailable }
nonisolated final class LivePitchAudioCapture: @unchecked Sendable {
    typealias PitchHandler = @Sendable ([PitcheeF0Frame]) -> Void
    typealias ErrorHandler = @Sendable (Error) -> Void
    func start(writingTo url: URL, analyzer: PitcheeCoreAnalyzer,
               onPitch: @escaping PitchHandler, onError: @escaping ErrorHandler,
               onRecordingError: ErrorHandler?) throws {
        let format = AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 16_000)!
        buffer.frameLength = 16_000
        for index in 0..<16_000 {
            buffer.floatChannelData![0][index] = Float(sin(Double(index) * 2 * .pi * 200 / 16_000) * 0.2)
        }
        do {
            let file = try AVAudioFile(forWriting: url, settings: format.settings)
            try file.write(from: buffer)
        }
        CaptureFixture.shared.started(url: url, handler: onRecordingError)
    }
    func finish() async -> Error? {
        let fixture = CaptureFixture.shared
        fixture.record("finish")
        await fixture.finishGate?.wait()
        fixture.record("closed")
        return fixture.finishFails ? CocoaError(.fileWriteOutOfSpace) : nil
    }
    func cancel() -> Task<Error?, Never> {
        CaptureFixture.shared.record("cancel")
        return Task.detached { nil }
    }
}

nonisolated struct PitcheeF0Frame: Sendable {
    let elapsedTime: Double
    let pitchHz: Double?
}
nonisolated enum PitcheeScoreProfile: Sendable { case feminization, masculinization }
actor PitcheeCoreAnalyzer {
    init() throws {}
    func resetRealtimeF0() throws {}
    func analyze(wavFile: URL, scoreProfile: PitcheeScoreProfile) throws -> PitcheeAnalysisResult {
        let file = try AVAudioFile(forReading: wavFile)
        precondition(file.length == 16_000, "Interrupted PCM must remain intact until analysis")
        CaptureFixture.shared.record("analyze")
        return PitcheeAnalysisResult(
            schemaVersion: 3, modelVersion: "lifecycle-test", scoreProfile: "feminization",
            audio: .init(sourceSampleRate: 16_000, sourceChannels: 1, inputSeconds: 1, analyzedSeconds: 1),
            vad: .init(segmentCount: 1, speechSeconds: 1, sileroSegmentCount: 1,
                       discardedBreathLikeCount: 0, trimmedSegmentCount: 0,
                       segments: [.init(startSeconds: 0, endSeconds: 1, speechStartSeconds: 0, speechEndSeconds: 1)]),
            f0: .init(windowSeconds: 0.1, meanHz: 200, standardDeviationHz: 0,
                      voicedFrameCount: 10, voicedWindowCount: 10, windows: []),
            vfp: .init(vfpStandardScore: 75, windowCount: 1, windowDurationSeconds: 1, windows: []),
            naturalness: .init(score: 80, windowCount: 1, windowDurationSeconds: 1, windows: []),
            composite: .init(baseScore: 75, finalScore: 75, cap: nil, rule: "continuous", limited: false, boosted: false)
        )
    }
}

// Opt-in stores are excluded so tests cannot read/write the user's local studies.
final class LocalDiagnosticsStore {
    struct AttemptToken {}
    static let shared = LocalDiagnosticsStore()
    func beginAttempt() -> AttemptToken? { nil }
    func finish(_ token: AttemptToken?, outcome: DiagnosticOutcome, observation: DiagnosticObservation) {}
}
final class LocalScoreStudyStore {
    struct Authorization {}
    struct Attempt { let direction: ScoreStudyDirection }
    static let shared = LocalScoreStudyStore()
    func authorizeRecording() -> Authorization? { nil }
    func invite(authorizedBy: Authorization?, direction: ScoreStudyDirection?) -> Attempt? { nil }
    func respond(_ attempt: Attempt, feedback: ScoreStudyFeedback) {}
    func finish(_ attempt: Attempt?, pair: ScoreStudyPair?, failed: Bool) {}
}
