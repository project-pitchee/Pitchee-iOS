//
//  LivePitchAudioCapture.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/18.
//

import AVFoundation
import Accelerate
import Foundation

/// Records microphone audio and feeds contiguous 16 kHz PCM to Core's realtime
/// SwiftF0 stream. File writes and sample conversion stay off the audio thread.
nonisolated final class LivePitchAudioCapture: @unchecked Sendable {
    typealias PitchHandler = @Sendable ([PitcheeF0Frame]) -> Void
    typealias LevelHandler = @Sendable (Double) -> Void
    typealias ErrorHandler = @Sendable (Error) -> Void

    private let audioEngine = AVAudioEngine()
    private let pitchQueue = DispatchQueue(
        label: "com.lvyzhan.Pitchee.live-pitch",
        qos: .userInitiated
    )
    private var pitchTask: Task<Void, Never>?
    private var pitchInput: AsyncStream<[Float]>.Continuation?

    private var recordingFile: AVAudioFile?
    private var recordingError: Error?
    private var acceptingBuffers = false
    private var hasInputTap = false

    func start(
        writingTo url: URL,
        analyzer: PitcheeCoreAnalyzer,
        onPitch: @escaping PitchHandler,
        onLevel: @escaping LevelHandler,
        onError: @escaping ErrorHandler
    ) throws {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
            throw LivePitchAudioCaptureError.inputUnavailable
        }

        // Hardware formats vary between devices. Passing `inputFormat.settings`
        // through can produce WAVE_FORMAT_EXTENSIBLE, while PitcheeCore accepts
        // canonical PCM16/PCM32/Float32 WAV files. Keep the engine-side client
        // format as Float32 for pitch tracking, but always encode a PCM16 WAV.
        let fileSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: inputFormat.sampleRate,
            AVNumberOfChannelsKey: Int(inputFormat.channelCount),
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        let file = try AVAudioFile(
            forWriting: url,
            settings: fileSettings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        let converter = try LivePitchPCMConverter(sampleRate: inputFormat.sampleRate)
        let (stream, continuation) = AsyncStream<[Float]>.makeStream()
        pitchInput = continuation
        pitchTask = Task(priority: .userInitiated) {
            do {
                for await samples in stream {
                    guard !Task.isCancelled else { return }
                    let frames = try await analyzer.processRealtimeF0(samples: samples)
                    guard !Task.isCancelled else { return }
                    if !frames.isEmpty { onPitch(frames) }
                }
            } catch {
                guard !Task.isCancelled else { return }
                onError(error)
            }
        }
        recordingFile = file
        recordingError = nil
        acceptingBuffers = true
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1_024,
            format: inputFormat
        ) { [weak self] buffer, _ in
            // The tap owns its buffer only until this callback returns. Copy it
            // before serializing file writes and detection off the audio thread.
            guard let self, let copy = Self.copyBuffer(buffer) else { return }
            self.pitchQueue.async {
                guard self.acceptingBuffers else { return }
                do {
                    try self.recordingFile?.write(from: copy)
                } catch {
                    self.recordingError = error
                }
                guard let samples = Self.monoSamples(from: copy) else { return }
                var rms: Float = 0
                vDSP_rmsqv(samples, 1, &rms, vDSP_Length(samples.count))
                onLevel(min(1, max(0, (20 * log10(Double(max(rms, 0.000_001))) + 60) / 50)))
                guard !converter.hasFailed else { return }
                do {
                    let converted = try converter.convert(samples)
                    if !converted.isEmpty { continuation.yield(converted) }
                } catch {
                    converter.hasFailed = true
                    continuation.finish()
                    onError(error)
                }
            }
        }
        hasInputTap = true

        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            stop()
            throw error
        }
    }

    @discardableResult
    func stop() -> Error? {
        if hasInputTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInputTap = false
        }
        audioEngine.stop()
        audioEngine.reset()
        // Drain pending writes before closing the WAV and handing it to Core.
        return pitchQueue.sync {
            acceptingBuffers = false
            pitchInput?.finish()
            pitchInput = nil
            pitchTask?.cancel()
            pitchTask = nil
            recordingFile = nil
            return recordingError
        }
    }

    private static func copyBuffer(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let copy = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameLength) else {
            return nil
        }
        copy.frameLength = buffer.frameLength
        let source = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
        let destination = UnsafeMutableAudioBufferListPointer(copy.mutableAudioBufferList)
        for index in source.indices {
            guard let input = source[index].mData, let output = destination[index].mData else { return nil }
            memcpy(output, input, Int(source[index].mDataByteSize))
        }
        return copy
    }

    static func monoSamples(from buffer: AVAudioPCMBuffer) -> [Float]? {
        guard let channels = buffer.floatChannelData else { return nil }

        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        guard frameCount > 0, channelCount > 0 else { return nil }

        if channelCount == 1 {
            return Array(UnsafeBufferPointer(start: channels[0], count: frameCount))
        }

        var samples = [Float](repeating: 0, count: frameCount)
        let scale = 1 / Float(channelCount)
        for channelIndex in 0..<channelCount {
            let channel = buffer.format.isInterleaved ? channels[0] + channelIndex : channels[channelIndex]
            let stride = buffer.format.isInterleaved ? channelCount : 1
            for frameIndex in 0..<frameCount {
                samples[frameIndex] += channel[frameIndex * stride] * scale
            }
        }
        return samples
    }
}

/// One converter per recording preserves resampling state across tap buffers.
/// This adapter only prepares PCM; Core performs all pitch calculations.
nonisolated final class LivePitchPCMConverter {
    private let inputFormat: AVAudioFormat
    private let outputFormat: AVAudioFormat
    private let converter: AVAudioConverter?
    // Accessed only on the capture queue, along with the converter.
    var hasFailed = false

    init(sampleRate: Double) throws {
        guard sampleRate.isFinite, sampleRate > 0,
              let input = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let output = AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1) else {
            throw LivePitchAudioCaptureError.inputUnavailable
        }
        inputFormat = input
        outputFormat = output
        if sampleRate == 16_000 {
            converter = nil
        } else {
            guard let converter = AVAudioConverter(from: input, to: output) else {
                throw LivePitchAudioCaptureError.conversionFailed
            }
            converter.primeMethod = .none
            self.converter = converter
        }
    }

    func convert(_ samples: [Float]) throws -> [Float] {
        guard !samples.isEmpty else { return [] }
        guard let converter else { return samples }
        guard let input = AVAudioPCMBuffer(
            pcmFormat: inputFormat, frameCapacity: AVAudioFrameCount(samples.count)
        ), let inputData = input.floatChannelData else {
            throw LivePitchAudioCaptureError.conversionFailed
        }
        input.frameLength = input.frameCapacity
        samples.withUnsafeBufferPointer { source in
            inputData[0].update(from: source.baseAddress!, count: source.count)
        }
        let capacity = AVAudioFrameCount(ceil(Double(samples.count) * 16_000 / inputFormat.sampleRate)) + 256
        guard let output = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: capacity) else {
            throw LivePitchAudioCaptureError.conversionFailed
        }
        var suppliedInput = false
        var result: [Float] = []
        while true {
            var error: NSError?
            let status = converter.convert(to: output, error: &error) { _, inputStatus in
                if suppliedInput {
                    inputStatus.pointee = .noDataNow
                    return nil
                }
                suppliedInput = true
                inputStatus.pointee = .haveData
                return input
            }
            if let error { throw error }
            guard status != .error else { throw LivePitchAudioCaptureError.conversionFailed }
            if let data = output.floatChannelData, output.frameLength > 0 {
                result.append(contentsOf: UnsafeBufferPointer(start: data[0], count: Int(output.frameLength)))
            }
            if status != .haveData { return result }
            output.frameLength = 0
        }
    }
}

nonisolated enum LivePitchAudioCaptureError: Error {
    case inputUnavailable
    case conversionFailed
}
