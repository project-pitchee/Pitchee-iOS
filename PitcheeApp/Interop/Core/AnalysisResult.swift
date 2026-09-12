//
//  AnalysisResult.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/13.
//

import Foundation

nonisolated public struct PitcheeAnalysisResult: Decodable, Sendable {
    public let schemaVersion: Int
    public let modelVersion: String
    public let audio: Audio
    public let vad: VoiceActivity
    public let pitch: Pitch
    public let models: Models
    public let composite: CompositeScore

    public struct Audio: Decodable, Sendable {
        public let sourceSampleRate: Int
        public let sourceChannels: Int
        public let inputSeconds: Double
        public let analyzedSeconds: Double
    }

    public struct VoiceActivity: Decodable, Sendable {
        public let segmentCount: Int
        public let speechSeconds: Double
        public let sileroSegmentCount: Int
        public let discardedBreathLikeCount: Int
        public let trimmedSegmentCount: Int
        public let segments: [Segment]
    }

    public struct Segment: Decodable, Sendable {
        public let startSeconds: Double
        public let endSeconds: Double
        public let speechStartSeconds: Double
        public let speechEndSeconds: Double
    }

    public struct Pitch: Decodable, Sendable {
        public let meanHz: Double?
        public let standardDeviationHz: Double?
        public let voicedFrameCount: Int
    }

    public struct Models: Decodable, Sendable {
        public let rawFemaleScore: Double
        public let standardScore: Double
        public let naturalnessScore: Double
        public let vfpWindowCount: Int
        public let vfpWindowDurationSeconds: Double
        public let vfpWindowStartsSeconds: [Double]
        public let vfpWindowRawScores: [Double]
        public let naturalnessPatchCount: Int
    }

    public struct CompositeScore: Decodable, Sendable {
        public let baseScore: Double
        public let finalScore: Double
        public let cap: Double?
        public let rule: String
        public let limited: Bool
        public let boosted: Bool
    }
}
