//
//  CoreAnalyzer.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/13.
//

import CPitcheeCore
import Foundation

/// Owns one native analyzer and serializes access to its C++ inference sessions.
public actor PitcheeCoreAnalyzer {
    private var handle: OpaquePointer?
    private var realtimeF0: OpaquePointer?
    private let decoder: JSONDecoder

    public init(modelDirectory: URL? = nil, threads: Int32 = 2) throws {
        let resolvedModelDirectory = try modelDirectory ?? PitcheeCore.bundledModelDirectory()
        var options = pitchee_analyzer_options_t(
            intra_op_threads: threads,
            use_coreml: 1,
            reserved: 0
        )
        var errorBuffer = [CChar](repeating: 0, count: 1_024)
        var createdHandle: OpaquePointer?

        let status = pitchee_analyzer_create(
            resolvedModelDirectory.path,
            &options,
            &createdHandle,
            &errorBuffer,
            errorBuffer.count
        )
        guard status == PITCHEE_SUCCESS, let createdHandle else {
            throw PitcheeCoreError(
                status: status,
                message: String(cString: errorBuffer)
            )
        }

        handle = createdHandle
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    deinit {
        if let realtimeF0 {
            pitchee_realtime_f0_destroy(realtimeF0)
        }
        if let handle {
            pitchee_analyzer_destroy(handle)
        }
    }

    /// Starts a new microphone timeline while reusing the loaded SwiftF0 model.
    public func resetRealtimeF0() throws {
        if let realtimeF0 {
            pitchee_realtime_f0_reset(realtimeF0)
            return
        }
        guard let handle else {
            throw PitcheeCoreError(message: "The PitcheeCore analyzer is unavailable.")
        }

        var stream: OpaquePointer?
        var errorBuffer = [CChar](repeating: 0, count: 1_024)
        let status = pitchee_realtime_f0_create(
            handle, nil, &stream, &errorBuffer, errorBuffer.count
        )
        guard status == PITCHEE_SUCCESS, let stream else {
            throw PitcheeCoreError(status: status, message: String(cString: errorBuffer))
        }
        realtimeF0 = stream
    }

    /// Consumes contiguous 16 kHz mono Float32 PCM. Core owns F0 estimation,
    /// voicing decisions and timestamps; all native inference stays serialized.
    public func processRealtimeF0(samples: [Float]) throws -> [PitcheeF0Frame] {
        try Task.checkCancellation()
        guard let realtimeF0 else {
            throw PitcheeCoreError(message: "The realtime F0 stream has not been started.")
        }
        var frames: [PitcheeF0Frame] = []
        var errorBuffer = [CChar](repeating: 0, count: 1_024)
        let status = withUnsafeMutablePointer(to: &frames) { output in
            samples.withUnsafeBufferPointer { buffer in
                pitchee_realtime_f0_process(
                    realtimeF0, buffer.baseAddress, buffer.count,
                    { frame, context in
                        guard let frame, let context else { return }
                        let value = frame.pointee
                        context.assumingMemoryBound(to: [PitcheeF0Frame].self).pointee.append(
                            PitcheeF0Frame(
                                elapsedTime: value.timestamp_seconds,
                                pitchHz: value.voiced == 0 ? nil : Double(value.f0_hz)
                            )
                        )
                    },
                    UnsafeMutableRawPointer(output), nil,
                    &errorBuffer, errorBuffer.count
                )
            }
        }
        guard status == PITCHEE_SUCCESS else {
            throw PitcheeCoreError(status: status, message: String(cString: errorBuffer))
        }
        return frames
    }

    public func analyze(
        samples: [Float],
        sampleRate: Int32,
        channels: Int32
    ) throws -> PitcheeAnalysisResult {
        guard let handle else {
            throw PitcheeCoreError(message: "The PitcheeCore analyzer is unavailable.")
        }

        var output: UnsafeMutablePointer<CChar>?
        var errorBuffer = [CChar](repeating: 0, count: 1_024)
        let status = samples.withUnsafeBufferPointer { buffer in
            pitchee_analyzer_analyze_pcm(
                handle,
                buffer.baseAddress,
                buffer.count,
                sampleRate,
                channels,
                nil,
                nil,
                &output,
                &errorBuffer,
                errorBuffer.count
            )
        }

        return try decodeOutput(
            status: status,
            output: output,
            errorMessage: String(cString: errorBuffer)
        )
    }

    public func analyze(wavFile: URL) throws -> PitcheeAnalysisResult {
        guard let handle else {
            throw PitcheeCoreError(message: "The PitcheeCore analyzer is unavailable.")
        }

        var output: UnsafeMutablePointer<CChar>?
        var errorBuffer = [CChar](repeating: 0, count: 1_024)
        let status = pitchee_analyzer_analyze_wav_file(
            handle,
            wavFile.path,
            nil,
            nil,
            &output,
            &errorBuffer,
            errorBuffer.count
        )

        return try decodeOutput(
            status: status,
            output: output,
            errorMessage: String(cString: errorBuffer)
        )
    }

    private func decodeOutput(
        status: pitchee_status_t,
        output: UnsafeMutablePointer<CChar>?,
        errorMessage: String
    ) throws -> PitcheeAnalysisResult {
        guard status == PITCHEE_SUCCESS, let output else {
            throw PitcheeCoreError(status: status, message: errorMessage)
        }
        defer { pitchee_string_free(output) }

        let json = String(cString: output)
        let data = Data(json.utf8)
        do {
            return try decoder.decode(PitcheeAnalysisResult.self, from: data)
        } catch {
            throw PitcheeCoreError(
                message: "Unable to decode analysis schema: \(error)"
            )
        }
    }
}

nonisolated public struct PitcheeF0Frame: Sendable {
    public let elapsedTime: TimeInterval
    public let pitchHz: Double?
}
