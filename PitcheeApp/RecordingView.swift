//
//  RecordingView.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/18.
//

import SwiftUI

struct RecordingView: View {
    @ObservedObject var viewModel: AnalysisViewModel
    @Binding var showsAnalysis: Bool

    var body: some View {
        FoldAwareArrangementView(
            primary: { chartPane },
            secondary: { referencePane },
            regular: { regularContent }
        )
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("recording.screen.title")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showsAnalysis) {
            RecordingAnalysisView(viewModel: viewModel)
        }
        .toolbar {
            if viewModel.hasResult {
                if #available(iOS 27.1, *) {
                    ToolbarItem(placement: .topBarPinnedTrailing) {
                        analysisButton
                    }
                    .axisBehavior(.verticalPreferred)
                    .visibilityPriority(.high)
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        analysisButton
                    }
                }
            }
        }
        .alert("recording.error.startFailed.title", isPresented: Binding(
            get: { viewModel.recordingError != nil && !showsAnalysis && !viewModel.hasResult },
            set: { if !$0 { viewModel.clearRecordingError() } }
        )) {
            Button("common.action.ok", role: .cancel) { viewModel.clearRecordingError() }
        } message: {
            Text(viewModel.recordingError ?? String(localized: "common.error.tryAgainLater"))
        }
    }

    private var analysisButton: some View {
        Button("recording.toolbar.viewLastAnalysis", systemImage: "clock.arrow.circlepath") {
            showsAnalysis = true
        }
    }

    private var regularContent: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 20)
                chart
                referenceText
                Spacer(minLength: 20)
            }
            .frame(maxWidth: 560)
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var chartPane: some View {
        ScrollView {
            chart
                .frame(maxWidth: 560)
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var referencePane: some View {
        ScrollView {
            referenceText
                .frame(maxWidth: 560)
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("recording.chart.recentWindow").font(.caption).foregroundStyle(.secondary)
                Spacer()
            }
            LivePitchChartView(
                samples: viewModel.livePitchSamples,
                elapsedTime: viewModel.elapsedTime,
                isRecording: viewModel.isRecording
            )
        }
    }

    private var referenceText: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("recording.reference.title")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("recording.reference.passage")
                .font(.body)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

#if DEBUG
import SwiftData

private struct RecordingViewPreview: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: AnalysisViewModel
    @State private var showsAnalysis = false

    init(state: AnalysisViewModel.State) {
        _viewModel = StateObject(wrappedValue: .preview(state: state))
    }

    var body: some View {
        TabView {
            NavigationStack {
                RecordingView(viewModel: viewModel, showsAnalysis: $showsAnalysis)
            }
            .tabItem { Label("recording.screen.title", systemImage: "waveform.badge.microphone") }
        }
        .modifier(RecordingTabAccessory(
            isVisible: !showsAnalysis,
            viewModel: viewModel,
            action: {
                viewModel.primaryButtonTapped(modelContext: modelContext)
                if viewModel.hasResult { showsAnalysis = true }
            }
        ))
    }
}

#Preview("Debug - Ready") {
    RecordingViewPreview(state: .idle)
        .modelContainer(for: RecordingAssessment.self, inMemory: true)
}

#Preview("Mock - Recording") {
    RecordingViewPreview(state: .recording)
        .modelContainer(for: RecordingAssessment.self, inMemory: true)
}
#endif
