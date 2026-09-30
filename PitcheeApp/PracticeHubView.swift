//
//  PracticeHubView.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/30.
//

import SwiftData
import SwiftUI

/// Entry point for the new guided practice flow. It lives behind the original
/// recording screen's toolbar so the established dashboard and recorder remain
/// visually unchanged.
struct PracticeHubView: View {
    @ObservedObject var model: AnalysisViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if model.isAwaitingFeedback, let direction = model.studyFeedbackDirection {
                ScoreStudyFeedbackView(direction: direction) { feedback in
                    model.submitStudyFeedback(feedback)
                }
            } else if model.isAnalyzing {
                VStack(spacing: 18) {
                    ProgressView().controlSize(.large)
                    Text("analysis.progress.title").font(.headline)
                    Text("analysis.progress.subtitle").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if model.hasResult, model.takes.count > 0 {
                ScrollView {
                    PracticeResultPanel(model: model,
                        repeatPractice: { _ = model.prepareRetake() },
                        finish: { if model.endPractice() { dismiss() } })
                        .frame(maxWidth: 560)
                        .frame(maxWidth: .infinity)
                        .padding(20)
                }
            } else {
                ScrollView {
                    PracticeSetupView(model: model)
                        .frame(maxWidth: 560)
                        .frame(maxWidth: .infinity)
                        .padding(20)
                }
            }
        }
        .navigationTitle("practice.screen.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.action.close") { dismiss() }
            }
            if model.practice != nil && !model.isAnalyzing && !model.isAwaitingFeedback && !model.hasResult {
                ToolbarItem(placement: .primaryAction) {
                    Button(model.isRecording ? "recording.controls.stopAndAnalyze" : "recording.controls.startRecording",
                           systemImage: model.isRecording ? "stop.fill" : "mic.fill") {
                        model.primaryButtonTapped(modelContext: modelContext)
                    }
                    .tint(model.isRecording ? .red : .accentColor)
                }
            }
        }
    }
}
