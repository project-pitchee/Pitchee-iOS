import AVFoundation
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
        }
        print("Pitch checks: \(checks) checks, \(failures) failures")
        if failures > 0 { exit(1) }
    }
}
