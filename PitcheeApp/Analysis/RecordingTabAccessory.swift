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
        content.modifier(TabBarAccessory(isVisible: isVisible) {
            RecordingAccessoryContent(viewModel: viewModel, action: action)
        })
    }
}

/// Recording and practice share one system-owned accessory above the tab bar.
struct TabBarAccessory<Accessory: View>: ViewModifier {
    let isVisible: Bool
    @ViewBuilder var accessory: () -> Accessory

    func body(content: Content) -> some View {
        if #available(iOS 26.1, *) {
            content.tabViewBottomAccessory(isEnabled: isVisible) {
                accessory()
            }
        } else if #available(iOS 26.0, *) {
            content.tabViewBottomAccessory {
                if isVisible {
                    accessory()
                }
            }
        } else {
            content.safeAreaInset(edge: .bottom, spacing: 0) {
                if isVisible {
                    accessory()
                        .background(.regularMaterial)
                }
            }
        }
    }
}

struct RecordingAccessoryContent: View {
    @ObservedObject var viewModel: AnalysisViewModel
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                if !dynamicTypeSize.isAccessibilitySize {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            RecordingAccessoryButton(
                symbol: actionSymbol,
                color: viewModel.needsAnalysisScreen ? .primary : .red,
                isPreparing: viewModel.isRequestingPermission,
                action: action
            )
            .accessibilityLabel(accessibilityLabel)
            .accessibilityIdentifier("recording.primaryAction")
            .accessibilityInputLabels([accessibilityLabel])
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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var actionSymbol: String {
        if viewModel.isRecording { return "stop.circle" }
        if viewModel.needsAnalysisScreen { return "arrow.up.right.circle" }
        return "record.circle"
    }

    private var accessibilityLabel: String {
        if viewModel.isRecording { return String(localized: "recording.controls.stopAndAnalyze") }
        if viewModel.needsAnalysisScreen { return String(localized: "recording.controls.viewAnalysisProgress") }
        return String(localized: "recording.controls.startRecording")
    }

    private var title: String {
        if viewModel.isRecording { return String(localized: "recording.controls.recordingInProgress") }
        if viewModel.isRequestingPermission { return String(localized: "recording.controls.preparingMicrophone") }
        if viewModel.needsAnalysisScreen { return String(localized: "recording.controls.analyzingAudio") }
        return String(localized: "recording.controls.startRecording")
    }

    private var subtitle: LocalizedStringKey {
        if viewModel.isRecording { return "recording.controls.stopAndAnalyze.subtitle" }
        if viewModel.isRequestingPermission { return "recording.controls.preparingMicrophone.subtitle" }
        if viewModel.needsAnalysisScreen { return "recording.controls.viewAnalysisProgress.subtitle" }
        return "recording.controls.startRecording.subtitle"
    }
}

/// Both audio tools use the same size, symbol treatment, and press feedback.
struct RecordingAccessoryButton: View {
    let symbol: String
    var color: Color = .red
    var iconSize: CGFloat = 32
    let isPreparing: Bool
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Group {
                if isPreparing {
                    ProgressView()
                        .tint(color)
                        .frame(width: iconSize, height: iconSize)
                } else {
                    Image(systemName: symbol)
                        .font(.system(size: iconSize, weight: .regular))
                        .symbolRenderingMode(.monochrome)
                        .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
                }
            }
            .foregroundStyle(color)
            .frame(width: 44, height: 44)
            .contentShape(Circle())
        }
        .buttonStyle(RecordingAccessoryPressStyle())
        .disabled(isPreparing)
    }
}

struct RecordingAccessoryPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.94 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
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
