import AVFoundation
import Foundation

nonisolated struct MonitorCaptureUpdate: Sendable {
    let samples: [Float]
    let pitchFrames: [PitcheeF0Frame]
    let spectrumFrames: [MonitorSpectrumFrame]
}

/// Owns the microphone engine, but leaves AVAudioSession policy to the page.
/// Each start supplies a fresh local timeline. Conversion, FFT, and Core F0 all
/// run off the realtime tap; the tap only copies into a bounded input stream.
nonisolated final class MonitorAudioCapture: @unchecked Sendable {
    private let audioEngine = AVAudioEngine()
    private let lifecycleLock = NSLock()
    private var currentRun: MonitorCaptureIngress?
    private var workerTask: Task<Void, Never>?
    private var hasInputTap = false

    func start(
        analyzer: PitcheeCoreAnalyzer?,
        onUpdate: @escaping @Sendable (MonitorCaptureUpdate) async -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) throws {
        lifecycleLock.lock()
        defer { lifecycleLock.unlock() }
        stopLocked()

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate.isFinite, format.sampleRate > 0, format.channelCount > 0,
              format.commonFormat == .pcmFormatFloat32 else {
            throw MonitorAudioCaptureError.inputUnavailable
        }
        let converter = try LivePitchPCMConverter(sampleRate: format.sampleRate)
        let spectrum = try MonitorSpectrumAnalyzer()
        let (stream, continuation) = AsyncThrowingStream<MonitorCapturedBuffer, Error>.makeStream(
            bufferingPolicy: .bufferingOldest(128)
        )
        let run = MonitorCaptureIngress(
            continuation: continuation,
            maximumFrameCount: Int(ceil(format.sampleRate * 2))
        )
        currentRun = run
        workerTask = Task.detached(priority: .userInitiated) { [weak self] in
            do {
                for try await captured in stream {
                    defer { run.release(frameCount: Int(captured.buffer.frameLength)) }
                    guard !Task.isCancelled, run.isActive else { return }
                    guard let mono = LivePitchAudioCapture.monoSamples(from: captured.buffer) else {
                        throw MonitorAudioCaptureError.invalidPCM
                    }
                    let samples = try converter.convert(mono)
                    guard !samples.isEmpty else { continue }
                    let spectrumFrames = spectrum.process(samples)
                    let pitchFrames: [PitcheeF0Frame]
                    if let analyzer {
                        pitchFrames = try await analyzer.processRealtimeF0(samples: samples)
                    } else {
                        pitchFrames = []
                    }
                    guard !Task.isCancelled, run.isActive else { return }
                    // Keep this input reserved until the timeline consumes its
                    // update. Backpressure must include main-actor delivery,
                    // not just conversion and inference, to bound retained PCM.
                    await onUpdate(MonitorCaptureUpdate(
                        samples: samples,
                        pitchFrames: pitchFrames,
                        spectrumFrames: spectrumFrames
                    ))
                }
            } catch {
                guard !Task.isCancelled, run.isActive else { return }
                self?.fail(run: run, error: error, onError: onError)
            }
        }

        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: format) { buffer, _ in
            run.enqueue(buffer)
        }
        hasInputTap = true
        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            stopLocked()
            throw error
        }
    }

    func stop() {
        lifecycleLock.lock()
        defer { lifecycleLock.unlock() }
        stopLocked()
    }

    deinit {
        stop()
    }

    private func stopLocked() {
        currentRun?.cancel()
        currentRun = nil
        workerTask?.cancel()
        workerTask = nil
        if hasInputTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInputTap = false
        }
        audioEngine.stop()
        audioEngine.reset()
    }

    private func fail(
        run: MonitorCaptureIngress,
        error: Error,
        onError: @escaping @Sendable (Error) -> Void
    ) {
        lifecycleLock.lock()
        guard currentRun === run, run.isActive else {
            lifecycleLock.unlock()
            return
        }
        stopLocked()
        lifecycleLock.unlock()
        onError(error)
    }
}

/// The engine's tap buffer is only valid during its callback. This wrapper owns
/// a private copy that is subsequently consumed by exactly one worker task.
private nonisolated struct MonitorCapturedBuffer: @unchecked Sendable {
    let buffer: AVAudioPCMBuffer
}

/// Bounds both the number of buffers and the total retained hardware frames,
/// including the buffer currently under analysis. An overrun explicitly fails
/// the run; discarded input can never silently compress the monitoring clock.
private nonisolated final class MonitorCaptureIngress: @unchecked Sendable {
    private let lock = NSLock()
    private let continuation: AsyncThrowingStream<MonitorCapturedBuffer, Error>.Continuation
    private let maximumFrameCount: Int
    private var retainedFrameCount = 0
    private var active = true
    private var accepting = true

    init(
        continuation: AsyncThrowingStream<MonitorCapturedBuffer, Error>.Continuation,
        maximumFrameCount: Int
    ) {
        self.continuation = continuation
        self.maximumFrameCount = maximumFrameCount
    }

    var isActive: Bool {
        lock.withLock { active }
    }

    func enqueue(_ buffer: AVAudioPCMBuffer) {
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return }
        lock.lock()
        guard active, accepting else {
            lock.unlock()
            return
        }
        guard frameCount <= maximumFrameCount - retainedFrameCount else {
            accepting = false
            lock.unlock()
            continuation.finish(throwing: MonitorAudioCaptureError.processingOverrun)
            return
        }
        retainedFrameCount += frameCount
        lock.unlock()

        guard let copy = Self.copy(buffer) else {
            fail(MonitorAudioCaptureError.copyFailed)
            return
        }
        lock.lock()
        guard active, accepting else {
            retainedFrameCount -= frameCount
            lock.unlock()
            return
        }
        let result = continuation.yield(MonitorCapturedBuffer(buffer: copy))
        switch result {
        case .enqueued:
            lock.unlock()
        case .dropped:
            retainedFrameCount -= frameCount
            accepting = false
            lock.unlock()
            continuation.finish(throwing: MonitorAudioCaptureError.processingOverrun)
        case .terminated:
            retainedFrameCount -= frameCount
            accepting = false
            lock.unlock()
        @unknown default:
            retainedFrameCount -= frameCount
            accepting = false
            lock.unlock()
            continuation.finish(throwing: MonitorAudioCaptureError.processingOverrun)
        }
    }

    func release(frameCount: Int) {
        lock.withLock { retainedFrameCount -= frameCount }
    }

    func cancel() {
        lock.withLock {
            active = false
            accepting = false
        }
        continuation.finish()
    }

    private func fail(_ error: Error) {
        lock.withLock { accepting = false }
        continuation.finish(throwing: error)
    }

    private static func copy(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let copy = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameLength) else {
            return nil
        }
        copy.frameLength = buffer.frameLength
        let source = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
        let destination = UnsafeMutableAudioBufferListPointer(copy.mutableAudioBufferList)
        guard source.count == destination.count else { return nil }
        for index in source.indices {
            guard let input = source[index].mData, let output = destination[index].mData,
                  destination[index].mDataByteSize >= source[index].mDataByteSize else { return nil }
            memcpy(output, input, Int(source[index].mDataByteSize))
        }
        return copy
    }
}

nonisolated enum MonitorAudioCaptureError: Error {
    case inputUnavailable
    case invalidPCM
    case copyFailed
    case processingOverrun
}
