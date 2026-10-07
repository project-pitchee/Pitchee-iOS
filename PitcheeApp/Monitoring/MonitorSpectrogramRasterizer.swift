//
//  MonitorSpectrogramRasterizer.swift
//  Pitchee
//
//  Created by Ryo on 2026/10/6.
//

import CoreGraphics
import Foundation

/// The rendered FFT column is retained alongside its capture timestamp so
/// scrolling and replay can reuse its pixels without repeating the analysis.
nonisolated struct MonitorSpectrogramColumn: Identifiable {
    let elapsedTime: TimeInterval
    let image: CGImage

    var id: TimeInterval { elapsedTime }
}

nonisolated enum MonitorSpectrogramRasterizer {
    static let rowCount = 512
    static let minimumDecibels: Float = -90
    static let maximumDecibels: Float = 0

    private static let frequencyRange = MonitorSpectrumFrame.frequencyRange
    private static let logarithmicSpan = log(frequencyRange.upperBound / frequencyRange.lowerBound)

    // Image rows run from high frequencies at the top to low frequencies at
    // the bottom. Keeping these edges fixed also aligns every history column.
    private static let frequencyEdges: [Double] = (0...rowCount).map { row in
        frequencyRange.upperBound * exp(-Double(row) / Double(rowCount) * logarithmicSpan)
    }

    private static let colorStops: [(red: Double, green: Double, blue: Double)] = [
        (18, 11, 112),
        (89, 15, 164),
        (189, 33, 151),
        (255, 128, 55),
        (255, 250, 74)
    ]

    /// A unit coordinate measured down from the top of the frequency axis.
    /// Frequencies outside the display range clamp to the nearest edge.
    static func verticalFraction(for frequency: Double) -> Double {
        guard !frequency.isNaN, frequency > frequencyRange.lowerBound else { return 1 }
        guard frequency < frequencyRange.upperBound else { return 0 }
        return log(frequencyRange.upperBound / frequency) / logarithmicSpan
    }

    static func makeColumn(frame: MonitorSpectrumFrame) -> CGImage? {
        guard frame.isValid, frame.elapsedTime.isFinite, frame.elapsedTime >= 0 else { return nil }
        let lastBin = frame.magnitudesDB.count - 1
        let nyquist = Double(lastBin) * frame.binWidthHz
        guard nyquist.isFinite else { return nil }

        var pixels = [UInt8](repeating: 255, count: rowCount * 4)
        for row in 0..<rowCount {
            let lowerFrequency = frequencyEdges[row + 1]
            let upperFrequency = min(nyquist, frequencyEdges[row])
            var magnitude = minimumDecibels

            // Each FFT bin represents a band half a bin wide on either side.
            // At low frequencies that band spans several image rows. At high
            // frequencies one row covers several bins: take their maximum so
            // a narrow harmonic cannot disappear between sampled pixels.
            // DC is excluded and frequencies above Nyquist remain background.
            if lastBin > 0, lowerFrequency <= upperFrequency,
               upperFrequency >= frame.binWidthHz / 2 {
                let lowerBin = min(Double(lastBin), max(1, floor(lowerFrequency / frame.binWidthHz + 0.5)))
                let upperBin = min(Double(lastBin), max(1, floor(upperFrequency / frame.binWidthHz + 0.5)))
                for bin in Int(lowerBin)...Int(upperBin) {
                    magnitude = max(magnitude, frame.magnitudesDB[bin])
                }
            }

            let color = color(for: magnitude)
            pixels[row * 4] = color.red
            pixels[row * 4 + 1] = color.green
            pixels[row * 4 + 2] = color.blue
        }

        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        return CGImage(
            width: 1,
            height: rowCount,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
                .union(.byteOrder32Big),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }

    private static func color(for decibels: Float) -> (red: UInt8, green: UInt8, blue: UInt8) {
        let level = Double(min(maximumDecibels, max(minimumDecibels, decibels)) - minimumDecibels)
            / Double(maximumDecibels - minimumDecibels)
        let position = level * Double(colorStops.count - 1)
        let lower = min(colorStops.count - 2, Int(position))
        let fraction = position - Double(lower)
        let first = colorStops[lower]
        let second = colorStops[lower + 1]
        return (
            UInt8((first.red + (second.red - first.red) * fraction).rounded()),
            UInt8((first.green + (second.green - first.green) * fraction).rounded()),
            UInt8((first.blue + (second.blue - first.blue) * fraction).rounded())
        )
    }
}
