//
//  PracticeViews.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/30.
//

import SwiftData
import SwiftUI

struct PracticeSetupView: View {
    @ObservedObject var model: AnalysisViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if model.canConfigurePractice {
                Text("practice.chooseFocus").font(.headline)
                ForEach(PracticeKind.allCases) { kind in
                    Button { model.selectPractice(kind) } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: model.practice?.kind == kind ? "checkmark.circle.fill" : "circle")
                            VStack(alignment: .leading, spacing: 5) {
                                Text(kind.title).font(.headline)
                                Text(kind.instruction).font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.pitcheeAccent.opacity(model.practice?.kind == kind ? 0.12 : 0.04), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(model.practice?.kind == kind ? .isSelected : [])
                }
            }
            if let practice = model.practice {
                Text(practice.kind.title).font(.title3.bold())
                Text(practice.target.title).font(.subheadline).foregroundStyle(.secondary)
                Text(practice.kind.instruction).font(.subheadline)
                Text(model.takes.isEmpty ? "practice.take.first" : "practice.take.second")
                    .font(.caption.bold()).foregroundStyle(.secondary)
                Text(practice.passage).font(.title3).lineSpacing(7)
                Text("practice.recording.instructions").font(.footnote).foregroundStyle(.secondary)
            }
            Label("practice.audio.lifetime", systemImage: "lock.shield")
                .font(.footnote).foregroundStyle(.secondary)
            if model.state == .idle, model.practice != nil {
                Button("practice.finish", role: .destructive) { model.endPractice() }
            }
        }
    }
}

struct RecordingQualityView: View {
    let quality: RecordingQuality?
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(quality?.canCompare == true ? "practice.quality.ready" : "practice.quality.excluded",
                  systemImage: quality?.canCompare == true ? "checkmark.circle" : "exclamationmark.circle")
                .font(.headline)
            if let quality {
                ForEach(quality.issues, id: \.rawValue) { issue in
                    Text(issue.advice).font(.subheadline)
                }
                if !quality.backgroundMeasured {
                    Text("practice.quality.noBackground").font(.footnote)
                }
            } else {
                Text("practice.quality.legacy").font(.subheadline)
            }
            Text("practice.quality.scope").font(.caption).foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((quality?.canCompare == true ? Color.teal : Color.orange).opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

struct PracticeResultPanel: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var captions = PracticeCaptions()
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var model: AnalysisViewModel
    @ObservedObject var playback: PracticePlayback
    let repeatPractice: () -> Void
    let finish: () -> Void

    init(model: AnalysisViewModel, repeatPractice: @escaping () -> Void, finish: @escaping () -> Void) {
        self.model = model
        playback = model.playback
        self.repeatPractice = repeatPractice
        self.finish = finish
    }

    var body: some View {
        if let practice = model.practice {
            VStack(alignment: .leading, spacing: 18) {
                Text(practice.kind.title).font(.title2.bold())
                Text(practice.kind.instruction).font(.subheadline).foregroundStyle(.secondary)
                Text(practice.passage).font(.body)
                ForEach(Array(model.takes.enumerated()), id: \.element.id) { index, take in
                    takeRow(take, index: index, metric: practice.kind.metric)
                }
                if model.takes.count == 2 {
                    comparison(metric: practice.kind.metric)
                    Text("practice.feedback.title").font(.headline)
                    ForEach(PracticeFeedback.allCases) { feedback in
                        Button {
                            // Defer published changes until SwiftUI finishes its current update.
                            Task { @MainActor in
                                model.saveComparisonFeedback(feedback, modelContext: modelContext)
                            }
                        } label: {
                            Label(feedback.title, systemImage: model.comparisonFeedback == feedback ? "checkmark.circle.fill" : "circle")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityAddTraits(model.comparisonFeedback == feedback ? .isSelected : [])
                    }
                    Text("practice.feedback.scope").font(.caption).foregroundStyle(.secondary)
                }
                if let error = playback.error ?? model.feedbackError ?? captions.error {
                    Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
                }
                Button("practice.repeat", systemImage: "arrow.clockwise", action: repeatPractice)
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    .disabled(model.needsAudioCleanup)
                if model.takes.count == 2 {
                    Text("practice.repeat.replacesB").font(.caption).foregroundStyle(.secondary)
                }
                Button("practice.finish", action: finish).buttonStyle(.bordered)
                Label("practice.audio.lifetime", systemImage: "lock.shield")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .onDisappear { playback.stop(); captions.clear() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background { captions.clear() }
            }
            .onChange(of: captions.error) { _, error in
                if let error { AccessibilityNotification.Announcement(error).post() }
            }
            .onChange(of: captions.transcripts) { _, transcripts in
                if !transcripts.isEmpty {
                    AccessibilityNotification.Announcement(String(localized: "practice.captions.ready")).post()
                }
            }
            .onChange(of: playback.error) { _, error in
                if let error { AccessibilityNotification.Announcement(error).post() }
            }
            .onChange(of: model.feedbackError) { _, error in
                if let error { AccessibilityNotification.Announcement(error).post() }
            }
        }
    }

    private func takeRow(_ take: PracticeTake, index: Int, metric: PracticeMetric) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            AccessibleStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(index == 0 ? "practice.take.first" : "practice.take.second").font(.headline)
                    Text(metric.title).font(.caption).foregroundStyle(.secondary)
                    Text(metric.formatted(metric.value(in: take.result)))
                        .font(.system(.title, design: .rounded).bold())
                }
                Spacer()
                Button {
                    playback.toggle(id: take.id, url: take.url)
                } label: {
                    Label(playback.playingID == take.id ? "practice.playback.stop" : "practice.playback.play",
                          systemImage: playback.playingID == take.id ? "stop.fill" : "play.fill")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(index == 0 ? "practice.playback.first" : "practice.playback.second")
                .accessibilityInputLabels([
                    Text(playback.playingID == take.id ? "practice.playback.stop" : "practice.playback.play"),
                    Text(index == 0 ? "practice.playback.first" : "practice.playback.second")
                ])
                .accessibilityValue(playback.playingID == take.id ? Text("practice.playback.playing") : Text("practice.playback.stopped"))
            }
            if let transcript = captions.transcripts[take.id] {
                Text("practice.captions.title").font(.headline).accessibilityAddTraits(.isHeader)
                Text(transcript).textSelection(.enabled)
                Text("practice.captions.accuracy").font(.caption).foregroundStyle(.secondary)
            } else if captions.activeID == take.id {
                ProgressView("practice.captions.generating")
                Button("practice.captions.cancel", action: captions.cancel)
                    .buttonStyle(.bordered)
            } else {
                Button("practice.captions.generate", systemImage: "captions.bubble") {
                    captions.generate(id: take.id, url: take.url)
                }
                .buttonStyle(.bordered)
                .disabled(captions.activeID != nil)
            }
            Text("practice.captions.privacy").font(.caption).foregroundStyle(.secondary)
            if !take.quality.canCompare {
                Text("practice.quality.excluded").font(.caption).foregroundStyle(.orange)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder private func comparison(metric: PracticeMetric) -> some View {
        let a = model.takes[0]
        let b = model.takes[1]
        if a.quality.canCompare, b.quality.canCompare,
           let before = metric.value(in: a.result), let after = metric.value(in: b.result) {
            VStack(alignment: .leading, spacing: 6) {
                Text("practice.comparison.change \(metric.formatted(after - before))").font(.headline)
                Text("practice.comparison.scope").font(.footnote).foregroundStyle(.secondary)
            }
        } else {
            Text("practice.comparison.unavailable").font(.subheadline).foregroundStyle(.secondary)
        }
    }
}

struct RecordingContextView: View {
    let assessment: RecordingAssessment
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let target = assessment.recordedTarget {
                HStack { Text("practice.history.target"); Text(target.title) }.font(.subheadline)
            } else {
                Text("practice.history.legacy").font(.subheadline)
            }
            if let practice = assessment.practice {
                Text(practice.kind.title).font(.subheadline)
            }
            if let version = assessment.scoringRulesVersion {
                Text("practice.history.version \(version)").font(.caption).foregroundStyle(.secondary)
            }
            if let raw = assessment.comparisonFeedbackRawValue, let feedback = PracticeFeedback(rawValue: raw) {
                Text("practice.history.feedback \(feedback.title)").font(.subheadline)
                Text("practice.feedback.scope").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
