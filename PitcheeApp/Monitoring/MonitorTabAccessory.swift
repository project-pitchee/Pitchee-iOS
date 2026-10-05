import SwiftUI

/// One compact row shares the recording tab's control appearance and press feedback.
struct MonitorAccessoryContent: View {
    let model: MonitorViewModel
    @State private var feedbackTrigger = 0
    @State private var rewindTrigger = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var capturingLive: Bool { model.state == .live }
    private var replayToggleEnabled: Bool {
        guard model.hasAudio, !model.isBusy else { return false }
        if model.state == .replaying { return true }
        return model.cursorTime > model.availableRange.lowerBound
    }

    private enum Metrics {
        static let controlFrame: CGFloat = 44
        // Use one optical icon size for all three transport controls. The
        // previous 22/32 split made the record symbol visibly larger.
        static let iconSize: CGFloat = 26
    }

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: model.kind.symbol)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Color.pitcheeAccent)
                    .frame(width: 26)
                    .accessibilityHidden(true)
                Text(LocalizedStringKey(model.kind.titleKey))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityValue(Text(LocalizedStringKey(model.statusKey)))
            .accessibilityIdentifier("monitor.status")

            HStack(spacing: 4) {
                replayButton
                rewindButton
                RecordingAccessoryButton(
                    symbol: capturingLive ? "stop.circle" : "record.circle",
                    iconSize: Metrics.iconSize,
                    isPreparing: model.isBusy
                ) {
                    perform {
                        if capturingLive { model.pause() } else { model.startOrResume() }
                    }
                }
                .accessibilityLabel(LocalizedStringKey(primaryAccessibilityKey))
                .accessibilityInputLabels([Text(LocalizedStringKey(primaryAccessibilityKey))])
                .accessibilityIdentifier("monitor.primaryAction")
            }
        }
        .frame(maxWidth: 560)
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.impact(weight: .light), trigger: feedbackTrigger)
    }

    private var rewindButton: some View {
        Button {
            model.rewindFiveSeconds()
            rewindTrigger &+= 1
            feedbackTrigger &+= 1
        } label: {
            rewindIcon
                .frame(width: Metrics.controlFrame, height: Metrics.controlFrame)
                .contentShape(Rectangle())
        }
        .buttonStyle(RecordingAccessoryPressStyle())
        .disabled(!model.canRewind || model.isBusy)
        .opacity(model.canRewind && !model.isBusy ? 1 : 0.3)
        .accessibilityLabel("monitor.action.rewindFive")
        .accessibilityHint("monitor.browse.hint")
        .accessibilityIdentifier("monitor.rewind")
    }

    @ViewBuilder
    private var rewindIcon: some View {
        let image = Image(systemName: "gobackward.5")
            .font(.system(size: Metrics.iconSize, weight: .regular))
            .foregroundStyle(.primary)
        if #available(iOS 18.0, *) {
            image.symbolEffect(.rotate, value: rewindTrigger)
        } else {
            image
        }
    }

    private var replayButton: some View {
        Button { perform { model.toggleReplay() } } label: {
            Image(systemName: model.state == .replaying ? "pause.fill" : "play.fill")
                .font(.system(size: Metrics.iconSize, weight: .regular))
                .foregroundStyle(.primary)
                .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
                .frame(width: Metrics.controlFrame, height: Metrics.controlFrame)
                .contentShape(Rectangle())
        }
        .buttonStyle(RecordingAccessoryPressStyle())
        .disabled(!replayToggleEnabled)
        .opacity(replayToggleEnabled ? 1 : 0.3)
        .accessibilityLabel(LocalizedStringKey(
            model.state == .replaying ? "monitor.action.pauseReplay" : "monitor.action.replayWindow"
        ))
        .accessibilityIdentifier("monitor.replay")
    }

    private func perform(_ action: () -> Void) {
        action()
        feedbackTrigger &+= 1
    }

    private var primaryAccessibilityKey: String {
        switch model.state {
        case .idle: "monitor.action.start"
        case .preparing: "monitor.status.preparing"
        case .live: "monitor.action.pause"
        case .paused: "monitor.action.resumeLive"
        case .replaying: "monitor.action.pauseReplay"
        }
    }
}
