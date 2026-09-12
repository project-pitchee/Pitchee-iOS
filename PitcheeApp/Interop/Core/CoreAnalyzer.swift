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
        if let handle {
            pitchee_analyzer_destroy(handle)
        }
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

        let data = Data(String(cString: output).utf8)
        return try decoder.decode(PitcheeAnalysisResult.self, from: data)
    }
}
