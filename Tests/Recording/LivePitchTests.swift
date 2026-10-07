//
//  LivePitchTests.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/19.
//

import AVFoundation
import CPitcheeCore
import Foundation

@main
enum LivePitchTests {
    static func tone(_ frequency: Double, rate: Double, amplitude: Double, duration: Double = 0.085) -> [Float] {
        // SwiftF0's voice-confidence gate can reject low pure sine waves.
        // Include harmonics to exercise voiced output without changing that gate.
        (0..<Int(rate * duration)).map { index in
            let phase = 2 * Double.pi * frequency * Double(index) / rate
            return Float(amplitude * (sin(phase) + 0.5 * sin(2 * phase) + 0.25 * sin(3 * phase)))
        }
    }

    static func main() async throws {
        var failures = 0
        var checks = 0
        func check(_ condition: Bool, _ message: String) {
            checks += 1
            if !condition {
                failures += 1
                print("FAIL: \(message)")
            }
        }
        guard CommandLine.arguments.count == 2 else {
            print("Usage: live-f0-tests <Core model directory>")
            exit(1)
        }
        let modelDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let analyzer = try PitcheeCoreAnalyzer(modelDirectory: modelDirectory)
        do {
            _ = try await analyzer.analyze(samples: [0.1, 0.2, 0.3], sampleRate: 16_000, channels: 2)
            check(false, "partial stereo frames must fail at the C API boundary")
        } catch let error as PitcheeCoreError {
            check(error.statusCode == Int(PITCHEE_ERROR_INVALID_ARGUMENT.rawValue),
                  "partial stereo frames return invalid argument")
        }
        do {
            _ = try await analyzer.processRealtimeF0(samples: [0])
            check(false, "processing before stream creation must fail")
        } catch is PitcheeCoreError {
            check(true, "processing before stream creation fails explicitly")
        }

        for rate in [16_000.0, 44_100, 48_000, 96_000] {
            try await analyzer.resetRealtimeF0()
            let converter = try LivePitchPCMConverter(sampleRate: rate)
            var convertedCount = 0
            func feed(_ samples: [Float]) async throws -> [PitcheeF0Frame] {
                var frames: [PitcheeF0Frame] = []
                for offset in stride(from: 0, to: samples.count, by: 1_024) {
                    let pcm = try converter.convert(Array(samples[offset..<min(offset + 1_024, samples.count)]))
                    convertedCount += pcm.count
                    frames += try await analyzer.processRealtimeF0(samples: pcm)
                }
                return frames
            }
            let empty = try await analyzer.processRealtimeF0(samples: [])
            check(empty.isEmpty, "empty PCM emits no frames")
            let warmup = try await feed(tone(130, rate: rate, amplitude: 0.2, duration: 0.2))
            check(warmup.isEmpty, "Core waits for its 320 ms context at \(rate)")
            let first = try await feed(tone(130, rate: rate, amplitude: 0.2, duration: 0.8))
            check(first.suffix(5).compactMap(\.pitchHz).contains { abs($0 - 130) < 5 },
                  "Core detects streaming 130 Hz at \(rate)")
            let changed = try await feed(tone(220, rate: rate, amplitude: 0.2, duration: 0.7))
            check(changed.suffix(5).compactMap(\.pitchHz).contains { abs($0 - 220) < 5 },
                  "Core detects streaming pitch change at \(rate)")
            let silent = try await feed([Float](repeating: 0, count: Int(rate * 0.7)))
            check(silent.count >= 5 && silent.suffix(5).allSatisfy { $0.pitchHz == nil },
                  "Core clears pitch during silence at \(rate)")
            let frames = first + changed + silent
            check(zip(frames, frames.dropFirst()).allSatisfy { $0.elapsedTime < $1.elapsedTime },
                  "Core timestamps are monotonic at \(rate)")
            check(frames.last.map { abs($0.elapsedTime - 2.4) < 0.06 } ?? false,
                  "Core timestamps track captured duration at \(rate)")
            check(abs(convertedCount - 38_400) <= 32,
                  "resampling preserves duration at \(rate): \(convertedCount) samples")
            try await analyzer.resetRealtimeF0()
            let restartedConverter = try LivePitchPCMConverter(sampleRate: rate)
            var restarted: [PitcheeF0Frame] = []
            let restartSignal = tone(440, rate: rate, amplitude: 0.2, duration: 0.6)
            for offset in stride(from: 0, to: restartSignal.count, by: 1_024) {
                let pcm = try restartedConverter.convert(Array(restartSignal[offset..<min(offset + 1_024, restartSignal.count)]))
                restarted += try await analyzer.processRealtimeF0(samples: pcm)
            }
            check(restarted.first.map { $0.elapsedTime < 0.07 } ?? false,
                  "reset starts a fresh timeline at \(rate)")
            check(restarted.last.map { $0.elapsedTime <= 0.6 } ?? false,
                  "reset does not retain the previous duration at \(rate)")
            check(restarted.suffix(5).compactMap(\.pitchHz).contains { abs($0 - 440) < 5 },
                  "reset does not retain the previous pitch at \(rate)")
        }

        // A canceled page preparation can still reach the analyzer's actor
        // after a new session has started. Reject its reset before touching
        // the native stream, preserving the active detector's time and context.
        try await analyzer.resetRealtimeF0()
        let beforeCanceledReset = try await analyzer.processRealtimeF0(
            samples: tone(220, rate: 16_000, amplitude: 0.2, duration: 0.5)
        )
        let canceledReset = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            do {
                try await analyzer.resetRealtimeF0()
                return false
            } catch is CancellationError {
                return true
            } catch {
                return false
            }
        }
        let resetWasCanceled = await canceledReset.value
        check(resetWasCanceled, "a canceled reset must throw CancellationError at the analyzer boundary")
        let afterCanceledReset = try await analyzer.processRealtimeF0(
            samples: tone(220, rate: 16_000, amplitude: 0.2, duration: 0.16)
        )
        check(beforeCanceledReset.last.map { last in
            !afterCanceledReset.isEmpty && afterCanceledReset.allSatisfy { $0.elapsedTime > last.elapsedTime }
        } ?? false, "a rejected canceled reset must preserve the ongoing native timeline")
        check(afterCanceledReset.compactMap(\.pitchHz).contains { abs($0 - 220) < 5 },
              "a rejected canceled reset must preserve warm detector context for a sub-context PCM batch")

        // Chunk boundaries must not restart the sample-rate converter.
        for rate in [44_100.0, 48_000, 96_000] {
            let signal = tone(220, rate: rate, amplitude: 0.2, duration: 1)
            let whole = try LivePitchPCMConverter(sampleRate: rate).convert(signal)
            let converter = try LivePitchPCMConverter(sampleRate: rate)
            var chunked: [Float] = []
            for offset in stride(from: 0, to: signal.count, by: 317) {
                chunked += try converter.convert(Array(signal[offset..<min(offset + 317, signal.count)]))
            }
            check(whole.count == chunked.count, "chunked resampling sample count at \(rate)")
            check(zip(whole, chunked).allSatisfy { abs($0 - $1) < 0.000_1 },
                  "chunked resampling continuity at \(rate)")
        }

        for interleaved in [false, true] {
            let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48_000,
                                       channels: 2, interleaved: interleaved)!
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4)!
            buffer.frameLength = 4
            let channels = buffer.floatChannelData!
            for channel in 0..<2 {
                for frame in 0..<4 {
                    let data = interleaved ? channels[0] + channel : channels[channel]
                    data[frame * (interleaved ? 2 : 1)] = Float(frame + channel * 2)
                }
            }
            check(LivePitchAudioCapture.monoSamples(from: buffer) == [1, 2, 3, 4],
                  "stereo extraction, interleaved=\(interleaved)")

            let copy = LivePitchAudioCapture.copyBuffer(buffer)!
            buffer.floatChannelData![0][0] = 99
            check(copy.frameLength == 4 && copy.format == format &&
                  LivePitchAudioCapture.monoSamples(from: copy) == [1, 2, 3, 4],
                  "tap copy owns independent PCM storage, interleaved=\(interleaved)")
        }

        // Hardware taps can vary in size. Reusing scratch storage must not
        // replay a previous buffer's tail, change channel mixing, or mutate
        // samples that have already been delivered to another task.
        for rate in [16_000.0, 44_100, 48_000, 96_000] {
            let signal = tone(220, rate: rate, amplitude: 0.2, duration: 0.4)
            let expected = try LivePitchPCMConverter(sampleRate: rate).convert(signal)
            for channelCount: AVAudioChannelCount in [1, 2] {
                for interleaved in [false, true] {
                    let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: rate,
                                               channels: channelCount, interleaved: interleaved)!
                    let converter = try LivePitchPCMConverter(sampleRate: rate)
                    let batchSizes = [317, 4_096, 1, 17, 1_024, 61, 2_048]
                    var offset = 0
                    var batchIndex = 0
                    var batches: [[Float]] = []
                    while offset < signal.count {
                        let count = min(batchSizes[batchIndex % batchSizes.count], signal.count - offset)
                        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(count))!
                        buffer.frameLength = AVAudioFrameCount(count)
                        for channelIndex in 0..<Int(channelCount) {
                            let data = interleaved ? buffer.floatChannelData![0] + channelIndex
                                                   : buffer.floatChannelData![channelIndex]
                            let sampleStride = interleaved ? Int(channelCount) : 1
                            for index in 0..<count {
                                // Distinct stereo channels average back to signal.
                                let gain: Float = channelCount == 1 ? 1 : (channelIndex == 0 ? 0.5 : 1.5)
                                data[index * sampleStride] = signal[offset + index] * gain
                            }
                        }
                        batches.append(try converter.convert(buffer))
                        offset += count
                        batchIndex += 1
                    }
                    let actual = batches.flatMap { $0 }
                    let context = "\(rate) Hz, \(channelCount) channel(s), interleaved=\(interleaved)"
                    check(actual.count == expected.count,
                          "varying tap sizes preserve duration after scratch buffers grow: \(context)")
                    check(zip(actual, expected).allSatisfy { abs($0 - $1) < 0.000_1 },
                          "direct PCM conversion preserves samples and prior returned arrays: \(context)")
                    let empty = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1)!
                    check(try converter.convert(empty).isEmpty, "empty tap emits no samples: \(context)")
                }
            }
        }

        let budget = AudioCaptureBufferBudget(maximumFrameCount: 10, maximumBufferCount: 2)
        check(budget.reserve(frameCount: 6) == .accepted && budget.reserve(frameCount: 4) == .accepted,
              "a capture budget includes every retained frame up to its exact limit")
        check(budget.reserve(frameCount: 1) == .overrun, "overrun is explicit instead of silently dropping PCM")
        budget.release(frameCount: 6)
        budget.release(frameCount: 4)
        check(budget.retainedFrames == 0 && budget.reserve(frameCount: 1) == .closed,
              "a failed stream cannot resume with a compressed sample clock")
        let reusableBudget = AudioCaptureBufferBudget(maximumFrameCount: 10)
        _ = reusableBudget.reserve(frameCount: 10)
        reusableBudget.release(frameCount: 10)
        check(reusableBudget.reserve(frameCount: 10) == .accepted,
              "consuming an input releases capacity for the next contiguous buffer")
        reusableBudget.release(frameCount: 10)
        reusableBudget.close()
        check(reusableBudget.reserve(frameCount: 1) == .closed, "closed ingress rejects later taps")

        let concurrentBudget = AudioCaptureBufferBudget(maximumFrameCount: 100, maximumBufferCount: 8)
        let admissions = CaptureTestEvents()
        DispatchQueue.concurrentPerform(iterations: 64) { _ in
            switch concurrentBudget.reserve(frameCount: 1) {
            case .accepted: admissions.record("accepted")
            case .overrun: admissions.record("overrun")
            case .closed: admissions.record("closed")
            }
        }
        check(admissions.count("accepted") == 8 && admissions.count("overrun") == 1 &&
              admissions.count("closed") == 55,
              "concurrent admission respects the buffer-count limit and reports one overrun")
        for _ in 0..<8 { concurrentBudget.release(frameCount: 1) }
        check(concurrentBudget.retainedFrames == 0, "all consumed concurrent reservations are released")

        // A 30 Hz presentation budget must use real elapsed time. Advancing
        // audio timestamps alone can otherwise flood UI work after inference
        // catches up, while a 200 ms threshold visibly steps the live curve.
        let presentationFrames = (0..<4).map { index in
            PitcheeF0Frame(elapsedTime: Double(index) * 0.01, pitchHz: index == 2 ? nil : 220)
        }
        var presentation = LivePitchFrameBatcher()
        presentation.append([presentationFrames[0]])
        check(presentation.takeIfDue(at: 100)?.map(\.elapsedTime) == [0],
              "the first available pitch frame can be displayed immediately")
        for index in 1..<presentationFrames.count {
            presentation.append([presentationFrames[index]])
            check(presentation.takeIfDue(at: 100 + Double(index) * 0.01) == nil,
                  "frames arriving inside one display interval are coalesced")
        }
        let adjacentFrames = presentation.takeIfDue(at: 100.04)
        check(adjacentFrames?.map(\.elapsedTime) == [0.01, 0.02, 0.03],
              "adjacent frames become visible within 50 ms without losing intermediate points")
        check(adjacentFrames?.map(\.pitchHz) == [220, nil, 220],
              "coalescing preserves the silence gap between voiced frames")
        check(presentation.deliveryDelay(at: 101) == nil,
              "a drained presentation batch requires no periodic wakeups")

        var backlogPresentation = LivePitchFrameBatcher()
        var backlogDeliveries: [[PitcheeF0Frame]] = []
        let backlogFrames = (0..<100).map { index in
            PitcheeF0Frame(elapsedTime: Double(index) * 0.2, pitchHz: 220)
        }
        for index in backlogFrames.indices {
            backlogPresentation.append([backlogFrames[index]])
            if let frames = backlogPresentation.takeIfDue(at: 200 + Double(index) * 0.0001) {
                backlogDeliveries.append(frames)
            }
        }
        check(backlogDeliveries.count == 1,
              "replaying 20 seconds of audio timestamps in 10 ms creates only one UI delivery")
        if let frames = backlogPresentation.takeIfDue(at: 200.04) { backlogDeliveries.append(frames) }
        check(backlogDeliveries.flatMap { $0 }.map(\.elapsedTime) == backlogFrames.map(\.elapsedTime),
              "the next wall-clock delivery retains every backlog frame in order")

        // Exercise the one-shot scheduler too: a final silent frame must not
        // wait for another detector result, and cancellation is terminal even
        // when a delayed delivery is already queued.
        let deliveryEvents = CaptureTestPitchDeliveries()
        let frameDelivery = LivePitchFrameDelivery { deliveryEvents.record($0) }
        frameDelivery.append([PitcheeF0Frame(elapsedTime: 0, pitchHz: 220)])
        check(await waitFor { deliveryEvents.batches.count == 1 },
              "the presentation scheduler delivers its first batch")
        frameDelivery.append([PitcheeF0Frame(elapsedTime: 0.01, pitchHz: nil)])
        check(await waitFor { deliveryEvents.batches.count == 2 },
              "a trailing silent frame is delivered without any subsequent detector batch")
        check(deliveryEvents.batches.flatMap { $0 }.map(\.elapsedTime) == [0, 0.01] &&
              deliveryEvents.batches.last?.last?.pitchHz == nil,
              "scheduled delivery retains the last silent frame exactly once")
        frameDelivery.append([PitcheeF0Frame(elapsedTime: 0.02, pitchHz: 330)])
        frameDelivery.cancel()
        let deliveriesAtCancellation = deliveryEvents.batches.count
        frameDelivery.append([PitcheeF0Frame(elapsedTime: 0.03, pitchHz: 440)])
        try await Task.sleep(for: .milliseconds(60))
        check(deliveryEvents.batches.count == deliveriesAtCancellation,
              "cancelled presentation neither flushes queued frames nor admits later ones")

        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("pitchee-capture-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let monoFormat = AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1)!
        func buffer(_ count: Int) -> AVAudioPCMBuffer {
            let buffer = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: AVAudioFrameCount(count))!
            buffer.frameLength = AVAudioFrameCount(count)
            for index in 0..<count { buffer.floatChannelData![0][index] = Float(index % 32) / 64 }
            return buffer
        }
        func run(
            _ name: String,
            events: CaptureTestEvents,
            processPitch: @escaping LivePitchRecordingRun.PitchProcessor = { _ in [] }
        ) throws -> (LivePitchRecordingRun, URL) {
            let url = temporaryDirectory.appendingPathComponent(name).appendingPathExtension("wav")
            let file = try AVAudioFile(forWriting: url, settings: monoFormat.settings)
            return (try LivePitchRecordingRun(
                file: file, sampleRate: 16_000, processPitch: processPitch,
                onPitch: { _ in events.record("pitchUpdate") },
                onError: { _ in events.record("pitchError") },
                onRecordingError: { _ in events.record("recordingError") }
            ), url)
        }

        let drainEvents = CaptureTestEvents()
        let (draining, drainedURL) = try run("graceful-drain", events: drainEvents)
        draining.enqueue(buffer(1_024))
        draining.enqueue(buffer(511))
        draining.close(discardingPendingWrites: false)
        check(draining.drainAndCloseFile() == nil, "graceful finish closes without a recording error")
        check(try AVAudioFile(forReading: drainedURL).length == 1_535,
              "graceful finish drains every accepted WAV frame before analysis")
        check(draining.pendingWriteFrameCount == 0 && draining.drainAndCloseFile() == nil,
              "drained file closure is idempotent and leaves no retained raw PCM")

        let copyingEvents = CaptureTestEvents()
        let (copyingRun, copyingURL) = try run("finish-during-copy", events: copyingEvents)
        let copyingBuffer = BlockingCopyCaptureBuffer(pcmFormat: monoFormat, frameCapacity: 1_024)!
        copyingBuffer.frameLength = 1_024
        copyingBuffer.floatChannelData![0].update(repeating: 0.25, count: 1_024)
        copyingBuffer.holdNextFormatRead()
        let ownedCopySource = CapturedAudioBuffer(buffer: copyingBuffer)
        let enqueueTask = Task.detached { copyingRun.enqueue(ownedCopySource.buffer) }
        check(await waitFor { copyingBuffer.events.count("copyStarted") == 1 },
              "test tap is reserved before copying finishes")
        copyingRun.close(discardingPendingWrites: false)
        let copyDrain = Task.detached {
            copyingEvents.record("drainStarted")
            let error = copyingRun.drainAndCloseFile()
            copyingEvents.record("drainCompleted")
            return error
        }
        _ = await waitFor { copyingEvents.count("drainStarted") == 1 }
        check(copyingEvents.count("drainCompleted") == 0,
              "graceful finish waits for a tap already accepted but still being copied")
        copyingBuffer.gate.signal()
        await enqueueTask.value
        check(await copyDrain.value == nil, "finishing during a tap copy closes successfully")
        check(try AVAudioFile(forReading: copyingURL).length == 1_024,
              "finishing during a tap copy preserves that complete final buffer")

        let failedPitchEvents = CaptureTestEvents()
        let (failedPitch, failedPitchURL) = try run("detector-error", events: failedPitchEvents) { _ in
            failedPitchEvents.record("pitchCall")
            throw CaptureTestError.detectorFailed
        }
        failedPitch.enqueue(buffer(1_024))
        check(await waitFor { failedPitchEvents.count("pitchError") == 1 },
              "a detector failure is reported")
        failedPitch.enqueue(buffer(512))
        failedPitch.enqueue(buffer(512))
        failedPitch.close(discardingPendingWrites: false)
        check(failedPitch.drainAndCloseFile() == nil, "a detector failure does not invalidate the WAV")
        check(try AVAudioFile(forReading: failedPitchURL).length == 2_048,
              "WAV recording continues after its pitch consumer exits")
        check(failedPitchEvents.count("pitchCall") == 1 && failedPitchEvents.count("pitchError") == 1 &&
              failedPitchEvents.count("recordingError") == 0,
              "detector failure closes its ingress permanently and reports only once")

        let overloadedPitchEvents = CaptureTestEvents()
        let gate = CaptureTestGate()
        let (overloadedPitch, overloadedPitchURL) = try run("detector-overrun", events: overloadedPitchEvents) { _ in
            overloadedPitchEvents.record("pitchCall")
            await gate.wait()
            return []
        }
        overloadedPitch.enqueue(buffer(32_000))
        check(await waitFor {
            overloadedPitchEvents.count("pitchCall") == 1 && overloadedPitch.pendingWriteFrameCount == 0
        }, "the detector may hold an in-flight input after its WAV write finishes")
        overloadedPitch.enqueue(buffer(1_024))
        check(await waitFor { overloadedPitchEvents.count("pitchError") == 1 },
              "in-flight pitch PCM counts toward the two-second backlog bound")
        overloadedPitch.enqueue(buffer(512))
        overloadedPitch.close(discardingPendingWrites: false)
        let overloadedPitchError = overloadedPitch.drainAndCloseFile()
        let overloadedPitchLength = try AVAudioFile(forReading: overloadedPitchURL).length
        check(overloadedPitchError == nil && overloadedPitchLength == 33_536,
              "pitch overload preserves every original WAV sample")
        await gate.open()
        check(overloadedPitchEvents.count("pitchCall") == 1 && overloadedPitchEvents.count("recordingError") == 0,
              "pitch overload never resumes inference after losing contiguous input")

        let rawEvents = CaptureTestEvents()
        let (overloadedRaw, overloadedRawURL) = try run("writer-overrun", events: rawEvents)
        overloadedRaw.enqueue(buffer(32_001))
        overloadedRaw.enqueue(buffer(1_024))
        overloadedRaw.close(discardingPendingWrites: false)
        let rawError = overloadedRaw.drainAndCloseFile() as? LivePitchAudioCaptureError
        if case .recordingOverrun? = rawError { check(true, "raw overrun rejects the take") }
        else { check(false, "raw overrun rejects the take") }
        check(await waitFor { rawEvents.count("recordingError") == 1 }, "raw overrun reports a fatal error once")
        check(try AVAudioFile(forReading: overloadedRawURL).length == 0,
              "rejected raw input never creates an apparently valid discontinuous recording")

        let writeEvents = CaptureTestEvents()
        let failedWriteURL = temporaryDirectory.appendingPathComponent("write-failure.wav")
        let failedWrite = try LivePitchRecordingRun(
            file: FailingCaptureAudioFile(forWriting: failedWriteURL, settings: monoFormat.settings),
            sampleRate: 16_000, processPitch: { _ in [] }, onPitch: { _ in }, onError: { _ in },
            onRecordingError: { _ in writeEvents.record("recordingError") }
        )
        failedWrite.enqueue(buffer(1_024))
        failedWrite.enqueue(buffer(512))
        failedWrite.close(discardingPendingWrites: false)
        if case .writeFailed? = failedWrite.drainAndCloseFile() as? CaptureTestError {
            check(true, "graceful drain propagates a pending disk-write failure")
        } else { check(false, "graceful drain propagates a pending disk-write failure") }
        check(await waitFor { writeEvents.count("recordingError") == 1 },
              "a disk-write failure reports one fatal capture error")
        check(failedWrite.pendingWriteFrameCount == 0,
              "discarded work after disk failure releases all frame reservations")

        let abandonedURL = temporaryDirectory.appendingPathComponent("cancel-writes.wav")
        var blockedFile: BlockingCaptureAudioFile? = try BlockingCaptureAudioFile(
            forWriting: abandonedURL, settings: monoFormat.settings
        )
        let writeGate = blockedFile!.gate
        let blockedEvents = blockedFile!.events
        let abandoned = try LivePitchRecordingRun(
            file: blockedFile!, sampleRate: 16_000, processPitch: { _ in [] },
            onPitch: { _ in }, onError: { _ in }
        )
        blockedFile = nil
        abandoned.enqueue(buffer(1_024))
        check(await waitFor { blockedEvents.count("started") == 1 }, "test writer holds one in-flight disk write")
        abandoned.enqueue(buffer(512))
        abandoned.close(discardingPendingWrites: true)
        check(abandoned.pendingWriteFrameCount == 1_536,
              "terminal cancellation returns while an in-flight disk write still owns PCM")
        writeGate.signal()
        check(abandoned.drainAndCloseFile() == nil && abandoned.pendingWriteFrameCount == 0,
              "cancellation completion drains ownership before the caller deletes the file")
        check(try AVAudioFile(forReading: abandonedURL).length == 1_024,
              "cancellation skips queued writes after completing the write already in progress")

        let cancelledCapture = LivePitchAudioCapture()
        let cancellation = cancelledCapture.cancel()
        let cancelledURL = temporaryDirectory.appendingPathComponent("cancelled-before-start.wav")
        do {
            try cancelledCapture.start(writingTo: cancelledURL, analyzer: analyzer, onPitch: { _ in }, onError: { _ in })
            check(false, "start after terminal cancellation must fail")
        } catch is CancellationError {
            check(true, "start after terminal cancellation must fail")
        }
        _ = await cancellation.value
        check(!FileManager.default.fileExists(atPath: cancelledURL.path),
              "cancel-before-start rejects startup before a temporary recording is created")
        let secondCancellation = cancelledCapture.cancel()
        let finishedError = await cancelledCapture.finish()
        let cancelledError = await secondCancellation.value
        check(finishedError == nil && cancelledError == nil,
              "repeated finish/cancel share successful terminal teardown")
        print("Pitch checks: \(checks) checks, \(failures) failures")
        if failures > 0 { exit(1) }
    }

    private static func waitFor(_ condition: () -> Bool) async -> Bool {
        let deadline = ProcessInfo.processInfo.systemUptime + 3
        while ProcessInfo.processInfo.systemUptime < deadline {
            if condition() { return true }
            try? await Task.sleep(for: .milliseconds(5))
        }
        return condition()
    }
}

private enum CaptureTestError: Error { case detectorFailed, writeFailed }

private final class FailingCaptureAudioFile: AVAudioFile, @unchecked Sendable {
    override func write(from buffer: AVAudioPCMBuffer) throws {
        throw CaptureTestError.writeFailed
    }
}

private final class BlockingCaptureAudioFile: AVAudioFile, @unchecked Sendable {
    let gate = DispatchSemaphore(value: 0)
    let events = CaptureTestEvents()
    override func write(from buffer: AVAudioPCMBuffer) throws {
        events.record("started")
        guard gate.wait(timeout: .now() + 5) == .success else { throw CaptureTestError.writeFailed }
        try super.write(from: buffer)
    }
}

private final class BlockingCopyCaptureBuffer: AVAudioPCMBuffer, @unchecked Sendable {
    let gate = DispatchSemaphore(value: 0)
    let events = CaptureTestEvents()
    private let lock = NSLock()
    private var holdsNextRead = false
    func holdNextFormatRead() { lock.withLock { holdsNextRead = true } }
    override var format: AVAudioFormat {
        let shouldWait = lock.withLock {
            let held = holdsNextRead
            holdsNextRead = false
            return held
        }
        if shouldWait {
            events.record("copyStarted")
            _ = gate.wait(timeout: .now() + 5)
        }
        return super.format
    }
}

private nonisolated final class CaptureTestEvents: @unchecked Sendable {
    private let lock = NSLock()
    private var events: [String: Int] = [:]
    func record(_ event: String) { lock.withLock { events[event, default: 0] += 1 } }
    func count(_ event: String) -> Int { lock.withLock { events[event, default: 0] } }
}

private nonisolated final class CaptureTestPitchDeliveries: @unchecked Sendable {
    private let lock = NSLock()
    private var deliveredBatches: [[PitcheeF0Frame]] = []
    var batches: [[PitcheeF0Frame]] { lock.withLock { deliveredBatches } }
    func record(_ frames: [PitcheeF0Frame]) {
        lock.withLock { deliveredBatches.append(frames) }
    }
}

private actor CaptureTestGate {
    private var opened = false
    private var continuation: CheckedContinuation<Void, Never>?
    func wait() async {
        if opened { return }
        await withCheckedContinuation { continuation = $0 }
    }
    func open() {
        opened = true
        continuation?.resume()
        continuation = nil
    }
}
