//
//  ContentView.swift
//  Pitchee
//
//  Created by Lvy Zhan on 2026/6/12.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("pitchee.onboarding.completed") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: hasCompletedOnboarding)
    }
}

private struct MainTabView: View {
    @State private var selectedTab: AppTab = .analysis

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                AnalysisView()
            }
            .tabItem {
                Label(AppTab.analysis.title, systemImage: AppTab.analysis.systemImage)
            }
            .tag(AppTab.analysis)

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label(AppTab.history.title, systemImage: AppTab.history.systemImage)
            }
            .tag(AppTab.history)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(AppTab.settings.title, systemImage: AppTab.settings.systemImage)
            }
            .tag(AppTab.settings)
        }
        .tint(.accentColor)
    }
}

private enum AppTab: Hashable {
    case analysis
    case history
    case settings

    var title: LocalizedStringKey {
        switch self {
        case .analysis:
            "分析"
        case .history:
            "记录"
        case .settings:
            "设置"
        }
    }

    var systemImage: String {
        switch self {
        case .analysis:
            "waveform"
        case .history:
            "clock.arrow.circlepath"
        case .settings:
            "gearshape"
        }
    }
}

private struct AnalysisView: View {
    @StateObject private var viewModel = AnalysisViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                intro
                recordButton
                status

                if let result = viewModel.result, viewModel.hasResult {
                    AnalysisResultCard(result: result)
                }
            }
            .frame(maxWidth: 560)
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .navigationTitle("分析")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "无法完成分析",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )
        ) {
            Button("好", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "请稍后再试。")
        }
    }

    private var intro: some View {
        VStack(spacing: 10) {
            Text(viewModel.hasResult ? "再录一段新的声音" : "开始你的声音分析")
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            Text("点击录音键即可开始，停止后会自动分析。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var recordButton: some View {
        recordingButton
            .frame(width: 220, height: 220)
    }

    private var recordingButton: some View {
        Button(action: viewModel.primaryButtonTapped) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 200, height: 200)

                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 160, height: 160)

                if viewModel.isAnalyzing {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.25)
                } else {
                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isAnalyzing)
        .accessibilityLabel(viewModel.isRecording ? "停止录音" : "开始录音")
        .accessibilityHint(viewModel.isRecording ? "停止后自动开始分析" : "点击后立即开始录音")
    }

    private var status: some View {
        VStack(spacing: 6) {
            if viewModel.isRecording {
                Text("正在录音")
                    .font(.headline)
                Text(formatDuration(viewModel.elapsedTime))
                    .font(.system(.title3, design: .monospaced).weight(.medium))
                    .foregroundStyle(.red)
            } else if viewModel.isAnalyzing {
                Text("正在分析声音…")
                    .font(.headline)
                Text("首次分析可能需要一点时间")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(viewModel.hasResult ? "点击录音键重新开始" : "点击录音键开始")
                    .font(.headline)
                Text("建议录制 5 秒以上的自然说话")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .contentTransition(.numericText())
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalCentiseconds = Int(duration * 100)
        let minutes = totalCentiseconds / 6_000
        let seconds = (totalCentiseconds / 100) % 60
        let centiseconds = totalCentiseconds % 100
        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }
}

private struct AnalysisResultCard: View {
    let result: PitcheeAnalysisResult

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("分析结果")
                .font(.headline)

            HStack(alignment: .lastTextBaseline) {
                Text(scoreText(result.composite.finalScore))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accentColor)

                Text("/ 100")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(result.composite.limited ? "评分已封顶" : "综合评分")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack(spacing: 12) {
                MetricView(title: "标准评分", value: scoreText(result.models.standardScore))
                MetricView(title: "自然度", value: scoreText(result.models.naturalnessScore))
            }

            HStack(spacing: 12) {
                MetricView(title: "平均音高", value: pitchText)
                MetricView(title: "有效语音", value: durationText)
            }
        }
        .padding(20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        }
    }

    private var pitchText: String {
        guard let meanHz = result.pitch.meanHz else { return "—" }
        return "\(scoreText(meanHz)) Hz"
    }

    private var durationText: String {
        let seconds = result.vad.speechSeconds
        return seconds < 60
            ? String(format: "%.1f 秒", seconds)
            : String(format: "%.1f 分钟", seconds / 60)
    }

    private func scoreText(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }
}

private struct MetricView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct HistoryView: View {
    var body: some View {
        ContentUnavailableView(
            "暂无记录",
            systemImage: "clock.arrow.circlepath",
            description: Text("完成一次分析后，历史记录会显示在这里。")
        )
        .navigationTitle("记录")
    }
}

private struct SettingsView: View {
    var body: some View {
        Form {
            Section("应用") {
                LabeledContent("版本", value: "1.0")
                LabeledContent("分析引擎", value: "PitcheeCore")
            }
        }
        .navigationTitle("设置")
    }
}

#Preview {
    ContentView()
}
