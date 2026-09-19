import AppKit
import SwiftUI

@main
enum PitchTimelineTests {
    @MainActor
    static func main() throws {
        var checks = 0
        func check(_ condition: Bool, _ message: String) {
            checks += 1
            if !condition { fatalError(message) }
        }

        let samples = stride(from: 0.0, through: 37.2, by: 0.05).map { time in
            LivePitchSample(
                elapsedTime: time,
                pitchHz: (17...19).contains(time) ? nil : 200 + 60 * sin(time * 2)
            )
        }
        let timeline = PitchTimeline(samples: samples, duration: 37.2)
        let rows = timeline.imageRows
        check(rows.count == 3, "The export must include audio beyond the live viewport")
        check(rows.first?.range.lowerBound == 0, "The image must begin at recording start")
        check(rows.last?.range.upperBound == 37.2, "The image must include the recording tail")
        check(zip(rows, rows.dropFirst()).allSatisfy { $0.range.upperBound == $1.range.lowerBound },
              "Image rows must have no missing time")
        check(samples.allSatisfy { sample in
            rows.contains { row in
                row.range.contains(sample.elapsedTime) && row.samples.contains { $0.id == sample.id }
            }
        }, "All original samples must appear in an image row")
        check(rows[1].samples.contains { $0.pitchHz == nil }, "Unvoiced gaps must survive export")

        let longTimeline = PitchTimeline(samples: [], duration: 7_201)
        check(longTimeline.imageRows.count <= 24, "Long recordings must use bounded image dimensions")
        check(longTimeline.imageRows.last?.range.upperBound == 7_201,
              "Long recordings must retain their complete time range")

        let renderer = ImageRenderer(content: PitchTimelineImage(timeline: timeline))
        renderer.scale = 2
        renderer.isOpaque = true
        guard let image = renderer.cgImage else { fatalError("Image rendering failed") }
        check(image.width == 1_920, "PNG must render at full export resolution")
        check(image.height > 1_100, "The renderer must include every row, not a viewport screenshot")
        let output = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
        let path = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/pitchee-pitch-export-preview.png"
        try output.write(to: URL(fileURLWithPath: path))
        let decoded = NSBitmapImageRep(data: output)
        check(decoded?.pixelsHigh == image.height, "Saved PNG must preserve full image height")

        let silence = PitchTimeline(samples: [LivePitchSample(elapsedTime: 0.1, pitchHz: nil)], duration: 0.2)
        let silenceRenderer = ImageRenderer(content: PitchTimelineImage(timeline: silence))
        check(silenceRenderer.cgImage != nil, "Short, unvoiced recordings must still export")
        print("Pitch image checks: \(checks) checks passed; preview: \(path)")
    }
}
