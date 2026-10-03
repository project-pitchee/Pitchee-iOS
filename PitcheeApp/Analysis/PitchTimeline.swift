//
//  PitchTimeline.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/19.
//

import Foundation

nonisolated struct LivePitchSample: Identifiable, Sendable {
    let elapsedTime: TimeInterval
    let pitchHz: Double?

    var id: TimeInterval { elapsedTime }
}

/// A bounded snapshot for chart exploration. Missing/unvoiced samples stay in
/// the table and split the audio graph, so silence is never reported as 0 Hz.
nonisolated struct PitchAccessibilitySnapshot: Identifiable, Sendable {
    let id = UUID()
    let range: ClosedRange<TimeInterval>
    let samples: [LivePitchSample]

    init(samples: [LivePitchSample], elapsedTime: TimeInterval) {
        let end = max(PitchTimeline.visibleSeconds, elapsedTime.isFinite ? elapsedTime : 0)
        let range = (end - PitchTimeline.visibleSeconds)...end
        self.range = range
        self.samples = samples.filter { $0.elapsedTime.isFinite && range.contains($0.elapsedTime) }
            .sorted { $0.elapsedTime < $1.elapsedTime }
    }

    var voicedSegments: [[LivePitchSample]] {
        var segments: [[LivePitchSample]] = []
        var current: [LivePitchSample] = []
        for sample in samples {
            guard let pitch = sample.pitchHz, pitch.isFinite, pitch > 0 else {
                if !current.isEmpty { segments.append(current); current = [] }
                continue
            }
            if let last = current.last, sample.elapsedTime - last.elapsedTime > 0.4 {
                segments.append(current)
                current = []
            }
            current.append(sample)
        }
        if !current.isEmpty { segments.append(current) }
        return segments
    }
}

nonisolated struct PitchTimeline: Sendable {
    static let visibleSeconds: TimeInterval = 3

    let samples: [LivePitchSample]
    let duration: TimeInterval

    init(samples: [LivePitchSample], duration: TimeInterval) {
        self.samples = samples
        self.duration = max(duration, samples.last?.elapsedTime ?? 0)
    }

    init(result: PitcheeAnalysisResult) {
        self.init(
            samples: result.f0.windows.map {
                LivePitchSample(elapsedTime: ($0.startSeconds + $0.endSeconds) / 2, pitchHz: $0.f0Hz)
            },
            duration: result.audio.analyzedSeconds
        )
    }

    /// Bound image dimensions for long recordings without dropping any time.
    /// Each row includes its neighboring samples so lines join at row boundaries.
    var imageRows: [Row] {
        let secondsPerRow = max(15, ceil(duration / 24 / 15) * 15)
        let rowCount = max(1, Int(ceil(duration / secondsPerRow)))
        var rows: [Row] = []
        var startIndex = 0
        var endIndex = 0
        for index in 0..<rowCount {
            let start = Double(index) * secondsPerRow
            let end = min(duration, start + secondsPerRow)
            while startIndex < samples.count, samples[startIndex].elapsedTime < start {
                startIndex += 1
            }
            while endIndex < samples.count, samples[endIndex].elapsedTime <= end {
                endIndex += 1
            }
            rows.append(Row(
                range: start...max(start + 0.001, end),
                samples: Array(samples[max(0, startIndex - 1)..<min(samples.count, endIndex + 1)])
            ))
        }
        return rows
    }

    nonisolated struct Row: Identifiable {
        let range: ClosedRange<TimeInterval>
        let samples: [LivePitchSample]
        var id: TimeInterval { range.lowerBound }
    }
}
