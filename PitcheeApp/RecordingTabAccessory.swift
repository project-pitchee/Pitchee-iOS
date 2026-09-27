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
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(viewModel.isRecording
                ? String(localized: "recording.controls.stopAndAnalyze.hint")
                : "")
        }
        .frame(maxWidth: 560)
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.isRecording)
    }

    private var accessibilityLabel: String {
        if viewModel.isRecording { return String(localized: "recording.controls.stopAndAnalyze") }
        if viewModel.isAnalyzing { return String(localized: "recording.controls.viewAnalysisProgress") }
        return String(localized: "recording.controls.startRecording")
    }

    private var title: String {
        if viewModel.isRecording { return String(localized: "recording.controls.recordingInProgress") }
        if viewModel.isRequestingPermission { return String(localized: "recording.controls.preparingMicrophone") }
        if viewModel.isAnalyzing { return String(localized: "recording.controls.analyzingAudio") }
        return String(localized: "recording.controls.startRecording")
    }

    private var subtitle: LocalizedStringKey {
        if viewModel.isRecording { return "recording.controls.stopAndAnalyze.subtitle" }
        if viewModel.isRequestingPermission { return "recording.controls.preparingMicrophone.subtitle" }
        if viewModel.isAnalyzing { return "recording.controls.viewAnalysisProgress.subtitle" }
        return "recording.controls.startRecording.subtitle"
    }
}

#if DEBUG
#Preview("Mock - Control States", traits: .sizeThatFitsLayout) {
    VStack(spacing: 24) {
        RecordingAccessoryContent(viewModel: .preview(state: .idle), action: {})
        RecordingAccessoryContent(viewModel: .preview(state: .requestingPermission), action: {})
        RecordingAccessoryContent(viewModel: .preview(state: .recording), action: {})
        RecordingAccessoryContent(viewModel: .preview(state: .analyzing), action: {})
    }
    .padding(.vertical)
}
#endif
