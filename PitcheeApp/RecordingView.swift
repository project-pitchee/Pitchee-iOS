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
        .navigationTitle("录制")
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
        .alert("无法开始录音", isPresented: Binding(
            get: { viewModel.errorMessage != nil && !showsAnalysis && !viewModel.hasResult },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("好", role: .cancel) { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "请稍后再试。")
        }
    }

    private var analysisButton: some View {
        Button("查看上次分析", systemImage: "clock.arrow.circlepath") {
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
                Text("最近 3 秒").font(.caption).foregroundStyle(.secondary)
                Spacer()
                PitchImageExportButton { viewModel.pitchTimeline }
                    .font(.caption)
                    .disabled(viewModel.elapsedTime <= 0 || viewModel.isAnalyzing)
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
            Text("参考语料")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("清晨，我推开窗户，看见阳光落在树叶上。远处传来轻轻的鸟鸣，街道也慢慢热闹起来。我想放慢脚步，用自然的声音，记录今天平凡而美好的生活。")
                .font(.body)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}
