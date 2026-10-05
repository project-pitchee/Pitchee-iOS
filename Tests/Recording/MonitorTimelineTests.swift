import AVFoundation
import Foundation

@main
enum MonitorTimelineTests {
    static func main() throws {
        var checks = 0
        var failures = 0
        func check(_ condition: @autoclosure () -> Bool, _ message: String) {
            checks += 1
            if !condition() {
                failures += 1
                print("FAIL: \(message)")
            }
        }
        let rate = MonitorTimeline.sampleRate
        let capacity = Int(rate * MonitorTimeline.retainedSeconds)
        func range(_ lower: Int, _ upper: Int) -> ClosedRange<TimeInterval> {
            (Double(lower) / rate)...(Double(upper) / rate)
        }
        func frame(_ time: Double, value: Float = -30) -> MonitorSpectrumFrame {
            .init(elapsedTime: time, magnitudesDB: [value, value - 12], binWidthHz: 7.8125)
        }

        var short = MonitorTimeline()
        check(short.duration == 0 && short.availableRange == 0...0, "An empty history starts at zero")
        check(short.audio(in: 0...5).isEmpty, "An empty history cannot replay audio")
        short.appendAudio([])
        short.appendPitch([.init(elapsedTime: 0, pitchHz: 220)])
        short.appendSpectra([frame(0)])
        check(short.pitchSamples.isEmpty && short.spectrumFrames.isEmpty, "Analysis needs captured audio")
        short.appendAudio([0, 1, 2, 3, 4, 5, 6])
        check(short.duration == 7 / rate, "Captured duration includes every PCM sample")
        check(short.audio(in: short.availableRange) == [0, 1, 2, 3, 4, 5, 6], "A short history returns all samples")
        check(short.audio(in: range(2, 5)) == [2, 3, 4], "Replay ranges include the first sample and exclude the end")
        check(short.audio(in: range(0, 2)) + short.audio(in: range(2, 7)) == [0, 1, 2, 3, 4, 5, 6],
              "Adjacent replay ranges concatenate without duplicate or missing PCM")
        check(short.audio(in: (2.25 / rate)...(5.25 / rate)) == [3, 4, 5], "Fractional boundaries select samples by their timestamps")
        check(short.audio(in: -10...10) == [0, 1, 2, 3, 4, 5, 6], "Replay clips both ends to the retained PCM")
        check(short.audio(in: -10...(-1)).isEmpty && short.audio(in: 1...2).isEmpty,
              "Ranges entirely outside capture return no PCM")
        check(short.audio(in: range(3, 3)).isEmpty, "A single cursor point is an empty replay interval")
        check(short.audio(in: 0...Double.infinity).isEmpty, "Non-finite ranges are rejected")
        check(short.audio(in: (-Double.infinity)...0).isEmpty, "A non-finite start is rejected")

        // Deliberately cross the 60-second boundary inside irregular chunks,
        // then wrap the circular storage more than twice. Index-valued samples
        // let the checks detect gaps, duplicates, and incorrect ring ordering.
        var rolling = MonitorTimeline()
        let sampleCount = capacity * 2 + 18_007
        let source = (0..<sampleCount).map(Float.init)
        let chunkSizes = [317, 1_013, 16_001, 16_381, 8_039]
        var offset = 0
        var chunk = 0
        while offset < source.count {
            let end = min(source.count, offset + chunkSizes[chunk % chunkSizes.count])
            rolling.appendAudio(Array(source[offset..<end]))
            offset = end
            chunk += 1
            if offset > capacity {
                check(rolling.availableRange.lowerBound == Double(offset - capacity) / rate,
                      "The oldest retained sample advances inside capture chunks")
                check(rolling.duration == Double(offset) / rate, "Duration remains monotonic after ring wrap")
            }
        }
        let expectedStart = sampleCount - capacity
        check(rolling.availableRange == range(expectedStart, sampleCount), "The ring retains exactly the latest 60 seconds")
        check(rolling.audio(in: rolling.availableRange) == Array(source.suffix(capacity)),
              "Multiple ring wraps preserve all retained PCM in order")
        let sliceStart = expectedStart + 21_019
        let sliceEnd = sliceStart + 83_771
        check(rolling.audio(in: range(sliceStart, sliceEnd)) == Array(source[sliceStart..<sliceEnd]),
              "An interior slice remains sample accurate after ring wrap")
        check(rolling.audio(in: range(expectedStart - 10, expectedStart + 3)) == Array(source[expectedStart..<(expectedStart + 3)]),
              "A partially evicted replay starts with the exact oldest sample")
        check(rolling.audio(in: range(sampleCount - 3, sampleCount + 10)) == Array(source.suffix(3)),
              "A replay extending beyond capture ends with the exact last sample")
        check(rolling.audio(in: range(0, expectedStart)).isEmpty, "Evicted PCM never reappears")

        var oversized = MonitorTimeline()
        oversized.appendAudio([99, 98, 97])
        oversized.appendAudio(source)
        check(oversized.duration == Double(source.count + 3) / rate, "Oversized capture batches still advance the full timeline")
        check(oversized.audio(in: oversized.availableRange) == Array(source.suffix(capacity)),
              "An oversized batch retains only its newest 60 seconds")
        let snapshot = short
        short.appendAudio([7, 8])
        check(snapshot.audio(in: snapshot.availableRange) == [0, 1, 2, 3, 4, 5, 6],
              "A retained timeline snapshot keeps value semantics")

        var analyzed = MonitorTimeline()
        analyzed.appendAudio([Float](repeating: 0, count: capacity))
        analyzed.appendPitch([
            .init(elapsedTime: 0.25, pitchHz: 180),
            .init(elapsedTime: 1, pitchHz: 200),
            .init(elapsedTime: 3, pitchHz: 240),
            .init(elapsedTime: 2, pitchHz: nil),
            .init(elapsedTime: 2.5, pitchHz: .nan),
            .init(elapsedTime: 2.6, pitchHz: .infinity),
            .init(elapsedTime: 2.7, pitchHz: 0),
            .init(elapsedTime: 2.8, pitchHz: -220),
            .init(elapsedTime: -1, pitchHz: 200),
            .init(elapsedTime: 61, pitchHz: 200),
            .init(elapsedTime: .nan, pitchHz: 200)
        ])
        analyzed.appendSpectra([frame(0.25), frame(3), frame(1), frame(2), frame(-1), frame(61), frame(.nan)])
        check(analyzed.pitchSamples.map(\.elapsedTime) == [0.25, 1, 2, 2.5, 2.6, 2.7, 2.8, 3],
              "Pitch samples are sorted and invalid or unavailable timestamps are excluded")
        check(analyzed.pitchSamples.filter { $0.pitchHz == nil }.count == 5,
              "Silence and invalid detector values remain explicit gaps")
        check(analyzed.spectrumFrames.map(\.elapsedTime) == [0.25, 1, 2, 3],
              "Spectrum history is sorted and bounded by captured audio")
        analyzed.appendPitch([.init(elapsedTime: 1, pitchHz: 210)])
        analyzed.appendSpectra([frame(1, value: -20)])
        check(analyzed.pitchSamples.count == 8 && analyzed.pitchSamples[1].pitchHz == 210,
              "A duplicate pitch callback replaces its existing chart identity")
        check(analyzed.spectrumFrames.count == 4 && analyzed.spectrumFrames[1].magnitudesDB[0] == -20,
              "A duplicate spectrum callback replaces its existing frame")
        analyzed.appendSpectra([
            .init(elapsedTime: 4, magnitudesDB: [], binWidthHz: 1),
            .init(elapsedTime: 5, magnitudesDB: [.nan], binWidthHz: 1),
            .init(elapsedTime: 6, magnitudesDB: [-30], binWidthHz: .infinity),
            .init(elapsedTime: 7, magnitudesDB: [-30], binWidthHz: 0)
        ])
        check(analyzed.spectrumFrames.count == 4, "Invalid FFT frames never enter the chart")
        analyzed.appendAudio([Float](repeating: 0, count: Int(rate)))
        check(analyzed.availableRange == 1...61, "Capture and analysis share the retained range")
        check(analyzed.pitchSamples.first?.elapsedTime == 1 && analyzed.spectrumFrames.first?.elapsedTime == 1,
              "Pitch and spectrum eviction retain the exact oldest boundary")
        analyzed.appendAudio([0])
        check(analyzed.pitchSamples.first?.elapsedTime == 2 && analyzed.spectrumFrames.first?.elapsedTime == 2,
              "Partial-sample ring eviction also trims corresponding analysis")
        analyzed.appendPitch([.init(elapsedTime: 1, pitchHz: 999)])
        analyzed.appendSpectra([frame(1)])
        check(analyzed.pitchSamples.first?.elapsedTime == 2 && analyzed.spectrumFrames.first?.elapsedTime == 2,
              "A delayed callback cannot restore evicted analysis")
        check(analyzed.audio(in: analyzed.availableRange).allSatisfy { $0 == 0 }, "Silence is retained and replayed as PCM silence")

        // A stopped microphone has no wall-clock gap. A new capture session's
        // relative detector timestamps are offset by the saved PCM duration.
        var resumed = MonitorTimeline()
        resumed.appendAudio([Float](repeating: 1, count: Int(rate)))
        resumed.appendPitch([.init(elapsedTime: 0.8, pitchHz: 180)])
        resumed.appendSpectra([frame(0.9)])
        let resumeOffset = resumed.duration
        resumed.appendAudio([Float](repeating: 2, count: Int(rate / 2)))
        resumed.appendPitch([
            .init(elapsedTime: resumeOffset + 0.1, pitchHz: nil),
            .init(elapsedTime: resumeOffset + 0.4, pitchHz: 220)
        ])
        resumed.appendSpectra([frame(resumeOffset + 0.128)])
        check(resumed.duration == 1.5, "Resume appends captured time without a wall-clock pause")
        check(resumed.pitchSamples.map(\.elapsedTime) == [0.8, 1.1, 1.4], "Resumed pitch keeps one contiguous time axis")
        check(resumed.spectrumFrames.last.map { abs($0.elapsedTime - 1.128) < 1e-12 } ?? false,
              "Resumed FFT timestamps share the PCM clock")
        check(resumed.audio(in: (1 - 2 / rate)...(1 + 2 / rate)) == [1, 1, 2, 2],
              "Replay crosses a pause and resume boundary without a duplicate or gap")

        for seconds in [5.0, 10, 30] {
            check(MonitorTimeline.window(endingAt: 80, duration: seconds, availableRange: 20...80) == (80 - seconds)...80,
                  "The \(Int(seconds))-second window ends at the cursor")
        }
        check(MonitorTimeline.window(endingAt: 1.5, duration: 5, availableRange: 0...1.5) == 0...1.5,
              "Short recordings use all available audio")
        check(MonitorTimeline.window(endingAt: 22, duration: 10, availableRange: 20...80) == 20...22,
              "A window near evicted history shrinks without moving the cursor")
        check(MonitorTimeline.window(endingAt: 10, duration: 5, availableRange: 20...80) == 20...20,
              "A cursor before retention clamps to the earliest available time")
        check(MonitorTimeline.window(endingAt: 100, duration: 5, availableRange: 20...80) == 75...80,
              "A cursor after capture clamps to the live edge")
        check(MonitorTimeline.window(endingAt: .nan, duration: 5, availableRange: 20...80) == 75...80,
              "An invalid cursor safely falls back to the live edge")
        check(MonitorTimeline.window(endingAt: 70, duration: -1, availableRange: 20...80) == 70...70,
              "A negative window is empty")
        check(MonitorTimeline.window(endingAt: 70, duration: .infinity, availableRange: 20...80) == 70...70,
              "An infinite window is empty")
        check(MonitorTimeline.window(endingAt: 0, duration: 5, availableRange: 0...Double.infinity) == 0...0,
              "Invalid available ranges yield an empty window")
        var cursor = 33.0
        cursor = MonitorTimeline.rewind(time: cursor, availableRange: 20...80)
        check(cursor == 28, "Rewind subtracts exactly five seconds")
        cursor = MonitorTimeline.rewind(time: cursor, availableRange: 20...80)
        check(cursor == 23, "Repeated rewind steps back through retained history")
        cursor = MonitorTimeline.rewind(time: cursor, availableRange: 20...80)
        check(cursor == 20, "Rewind clips a partial final step")
        for _ in 0..<10 { cursor = MonitorTimeline.rewind(time: cursor, availableRange: 20...80) }
        check(cursor == 20, "Repeated rewind cannot move before the retained history")
        check(MonitorTimeline.rewind(time: 100, availableRange: 20...80) == 75,
              "Rewind starts from the clamped live edge")
        check(MonitorTimeline.rewind(time: .nan, availableRange: 20...80) == 75,
              "Rewind tolerates an invalid cursor")
        check(MonitorTimeline.rewind(time: 70, by: -5, availableRange: 20...80) == 70,
              "Negative rewind never moves the cursor forward")
        check(MonitorTimeline.rewind(time: 70, by: .infinity, availableRange: 20...80) == 70,
              "Invalid rewind distances preserve the cursor")
        check(MonitorTimeline.clampedTime(10, availableRange: 20...80) == 20 &&
              MonitorTimeline.clampedTime(100, availableRange: 20...80) == 80,
              "Scrubbing clamps to both retained endpoints")

        // Read production encoder output through Apple's actual WAV decoder
        // and AVAudioPlayer, without starting sound or acquiring a microphone.
        let wavDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("pitchee-monitor-wav-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: wavDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: wavDirectory) }
        func unsignedLE(_ data: Data, offset: Int, bytes: Int) -> UInt32 {
            (0..<bytes).reduce(0) { $0 | UInt32(data[offset + $1]) << (8 * $1) }
        }
        func decode(_ data: Data, name: String) throws -> (AVAudioFile, AVAudioPCMBuffer) {
            let url = wavDirectory.appendingPathComponent(name).appendingPathExtension("wav")
            try data.write(to: url)
            let file = try AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                               frameCapacity: AVAudioFrameCount(file.length)) else {
                fatalError("Unable to allocate the WAV decode buffer")
            }
            try file.read(into: buffer)
            return (file, buffer)
        }

        let edgePCM: [Float] = [-2, -1, -0.5, 0, 0.5, 1, 2, .nan, .infinity, -.infinity]
        let edgeWAV = MonitorWaveEncoder.encode(edgePCM)
        check(edgeWAV.count == 64, "PCM16 WAV contains a 44-byte header and two bytes per sample")
        check(String(decoding: edgeWAV[0..<4], as: UTF8.self) == "RIFF" &&
              String(decoding: edgeWAV[8..<16], as: UTF8.self) == "WAVEfmt " &&
              String(decoding: edgeWAV[36..<40], as: UTF8.self) == "data",
              "The encoder emits canonical RIFF, WAVE, format, and data chunks")
        check(unsignedLE(edgeWAV, offset: 4, bytes: 4) == 56 &&
              unsignedLE(edgeWAV, offset: 16, bytes: 4) == 16 &&
              unsignedLE(edgeWAV, offset: 40, bytes: 4) == 20,
              "RIFF, format, and PCM chunk lengths match the encoded bytes")
        check(unsignedLE(edgeWAV, offset: 20, bytes: 2) == 1 &&
              unsignedLE(edgeWAV, offset: 22, bytes: 2) == 1 &&
              unsignedLE(edgeWAV, offset: 24, bytes: 4) == 16_000 &&
              unsignedLE(edgeWAV, offset: 28, bytes: 4) == 32_000 &&
              unsignedLE(edgeWAV, offset: 32, bytes: 2) == 2 &&
              unsignedLE(edgeWAV, offset: 34, bytes: 2) == 16,
              "WAV declares 16 kHz mono linear PCM16 with consistent byte rate and alignment")
        let (edgeFile, edgeBuffer) = try decode(edgeWAV, name: "sample-edges")
        check(edgeFile.length == AVAudioFramePosition(edgePCM.count) &&
              edgeFile.fileFormat.sampleRate == rate && edgeFile.fileFormat.channelCount == 1,
              "AVAudioFile decodes the exact sample count, rate, and channel count")
        let decodedEdges = Array(UnsafeBufferPointer(start: edgeBuffer.floatChannelData![0],
                                                      count: Int(edgeBuffer.frameLength)))
        let expectedEdges: [Float] = [-32_767, -32_767, -16_384, 0, 16_384, 32_767, 32_767, 0, 0, 0]
            .map { $0 / 32_768 }
        check(decodedEdges == expectedEdges,
              "Apple's decoder confirms clipping, signed PCM rounding, and silence for non-finite samples")
        let emptyWAV = MonitorWaveEncoder.encode([])
        check(emptyWAV.count == 44 && unsignedLE(emptyWAV, offset: 40, bytes: 4) == 0,
              "An empty PCM array produces a valid empty data chunk")

        var playbackTimeline = MonitorTimeline()
        playbackTimeline.appendAudio([Float](repeating: 0, count: Int(rate * 61.25)))
        for seconds in [5.0, 10, 30] {
            let selectedRange = MonitorTimeline.window(endingAt: 60.5, duration: seconds,
                                                        availableRange: playbackTimeline.availableRange)
            let selectedAudio = playbackTimeline.audio(in: selectedRange)
            let wav = MonitorWaveEncoder.encode(selectedAudio)
            let player = try AVAudioPlayer(data: wav)
            check(abs(player.duration - seconds) < 1 / rate && player.numberOfChannels == 1,
                  "AVAudioPlayer accepts the \(Int(seconds))-second selected replay window")
            let (_, buffer) = try decode(wav, name: "silence-\(Int(seconds))")
            let silencePCM = UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength))
            check(silencePCM.count == Int(seconds * rate) && silencePCM.allSatisfy { $0 == 0 },
                  "The \(Int(seconds))-second silence window decodes without extra samples or artifacts")
        }
        let shortWAV = MonitorWaveEncoder.encode(resumed.audio(in: resumed.availableRange))
        let shortPlayer = try AVAudioPlayer(data: shortWAV)
        check(abs(shortPlayer.duration - resumed.duration) < 1 / rate,
              "A replay shorter than the selected window retains its actual captured duration")

        print("Monitor timeline checks: \(checks) checks, \(failures) failures")
        if failures > 0 { exit(1) }
    }
}
