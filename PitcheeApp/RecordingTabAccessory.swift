//
//  RecordingTabAccessory.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/18.
//

import SwiftUI

/// Uses the system's shared glass surface so recording controls stay attached
/// to the tab bar and remain reachable when the page scrolls.
struct RecordingTabAccessory: ViewModifier {
    let isVisible: Bool
    @ObservedObject var viewModel: AnalysisViewModel
    let action: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 26.1, *) {
            content.tabViewBottomAccessory(isEnabled: isVisible) {
                RecordingAccessoryContent(viewModel: viewModel, action: action)
            }
        } else if #available(iOS 26.0, *) {
            content.tabViewBottomAccessory {
                if isVisible {
                    RecordingAccessoryContent(viewModel: viewModel, action: action)
                }
            }
        } else {
            content.safeAreaInset(edge: .bottom, spacing: 0) {
                if isVisible {
                    RecordingAccessoryContent(viewModel: viewModel, action: action)
                        .background(.regularMaterial)
                }
            }
        }
    }
}

private struct RecordingAccessoryContent: View {
    @ObservedObject var viewModel: AnalysisViewModel
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            Button(action: action) {
                Group {
                    if viewModel.isRequestingPermission {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: viewModel.isRecording ? "stop.fill" : (viewModel.isAnalyzing ? "arrow.up.right" : "mic.fill"))
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(viewModel.isRecording ? Color.red : Color.accentColor, in: Circle())
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isRequestingPermission)
            .accessibilityLabel(viewModel.isRecording ? "停止并分析" : (viewModel.isAnalyzing ? "查看分析进度" : "开始录音"))
            .accessibilityHint(viewModel.isRecording ? "结束录音并打开声音报告" : "")
        }
        .frame(maxWidth: 560)
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.isRecording)
    }

    private var title: String {
        if viewModel.isRecording { return String(localized: "录音中") }
        if viewModel.isRequestingPermission { return String(localized: "正在准备麦克风") }
        if viewModel.isAnalyzing { return String(localized: "正在分析声音") }
        return String(localized: "开始录音")
    }

    private var subtitle: LocalizedStringKey {
        if viewModel.isRecording { return "点击停止并分析" }
        if viewModel.isRequestingPermission { return "请允许使用麦克风" }
        if viewModel.isAnalyzing { return "点击查看进度" }
        return "自然朗读参考语料"
    }
}
