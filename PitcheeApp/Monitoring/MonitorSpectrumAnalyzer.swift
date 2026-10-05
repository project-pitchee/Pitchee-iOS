import Accelerate
import Foundation

/// A streaming, amplitude-calibrated spectrum for contiguous 16 kHz mono PCM.
/// Keep one instance per capture run so window overlap survives tap boundaries.
nonisolated final class MonitorSpectrumAnalyzer {
    static let sampleRate: Double = 16_000
    static let windowSize = 2_048
    static let hopSize = 1_600
    static let minimumDecibels: Float = -120

    private let fftSetup: FFTSetup
    private let log2WindowSize: vDSP_Length = 11
    private let window: [Float]
    private let windowSum: Float
    private var pendingSamples: [Float] = []
    private var windowStartSample: Int64 = 0
    private var windowedSamples = [Float](repeating: 0, count: windowSize)
    private var real = [Float](repeating: 0, count: windowSize / 2)
    private var imaginary = [Float](repeating: 0, count: windowSize / 2)

    init() throws {
        guard let setup = vDSP_create_fftsetup(log2WindowSize, FFTRadix(kFFTRadix2)) else {
            throw MonitorSpectrumAnalyzerError.allocationFailed
        }
        fftSetup = setup
        var coefficients = [Float](repeating: 0, count: Self.windowSize)
        vDSP_hann_window(&coefficients, vDSP_Length(Self.windowSize), Int32(vDSP_HANN_NORM))
        window = coefficients
        windowSum = coefficients.reduce(0, +)
        pendingSamples.reserveCapacity(Self.windowSize + Self.hopSize)
    }

    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }

    /// Returns 1,025 bins including DC and Nyquist, spaced 7.8125 Hz apart.
    /// Time identifies the end of the FFT window; partial windows wait for more
    /// samples rather than being padded, so batching never changes the result.
    func process(_ samples: [Float]) -> [MonitorSpectrumFrame] {
        guard !samples.isEmpty else { return [] }
        pendingSamples.append(contentsOf: samples)
        var consumed = 0
        var frames: [MonitorSpectrumFrame] = []

        while pendingSamples.count - consumed >= Self.windowSize {
            pendingSamples.withUnsafeBufferPointer { source in
                window.withUnsafeBufferPointer { coefficients in
                    windowedSamples.withUnsafeMutableBufferPointer { destination in
                        vDSP_vmul(
                            source.baseAddress! + consumed, 1,
                            coefficients.baseAddress!, 1,
                            destination.baseAddress!, 1,
                            vDSP_Length(Self.windowSize)
                        )
                    }
                }
            }
            let magnitudes = transformWindow()
            frames.append(MonitorSpectrumFrame(
                elapsedTime: Double(windowStartSample + Int64(Self.windowSize)) / Self.sampleRate,
                magnitudesDB: magnitudes,
                binWidthHz: Self.sampleRate / Double(Self.windowSize)
            ))
            consumed += Self.hopSize
            windowStartSample += Int64(Self.hopSize)
        }

        if consumed > 0 {
            pendingSamples.removeFirst(consumed)
        }
        return frames
    }

    private func transformWindow() -> [Float] {
        let halfSize = Self.windowSize / 2
        var decibels = [Float](repeating: Self.minimumDecibels, count: halfSize + 1)
        real.withUnsafeMutableBufferPointer { realBuffer in
            imaginary.withUnsafeMutableBufferPointer { imaginaryBuffer in
                var split = DSPSplitComplex(
                    realp: realBuffer.baseAddress!, imagp: imaginaryBuffer.baseAddress!
                )
                windowedSamples.withUnsafeBytes { source in
                    vDSP_ctoz(
                        source.bindMemory(to: DSPComplex.self).baseAddress!, 2,
                        &split, 1, vDSP_Length(halfSize)
                    )
                }
                vDSP_fft_zrip(fftSetup, &split, 1, log2WindowSize, FFTDirection(FFT_FORWARD))

                // vDSP's real FFT returns twice the conventional DFT. Hann's
                // coherent gain is its coefficient sum; DC/Nyquist are packed
                // into bin zero and do not receive the interior-bin doubling.
                decibels[0] = Self.decibels(abs(split.realp[0]) / (2 * windowSum))
                decibels[halfSize] = Self.decibels(abs(split.imagp[0]) / (2 * windowSum))
                for index in 1..<halfSize {
                    let magnitude = hypotf(split.realp[index], split.imagp[index]) / windowSum
                    decibels[index] = Self.decibels(magnitude)
                }
            }
        }
        return decibels
    }

    private static func decibels(_ amplitude: Float) -> Float {
        guard amplitude.isFinite, amplitude > 0 else { return minimumDecibels }
        return max(minimumDecibels, 20 * log10f(amplitude))
    }
}

nonisolated enum MonitorSpectrumAnalyzerError: Error {
    case allocationFailed
}
