//
//  SettingsView.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/18.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(AppStorageKey.voicePreference) private var savedVoicePreference = ""
    @AppStorage(AppStorageKey.customThemeColor) private var customThemeColor = ""

    private var selectedVoice: VoicePreference {
        VoicePreference(legacyStoredValue: savedVoicePreference) ?? .undecided
    }

    private var voicePreference: Binding<VoicePreference> {
        Binding(
            get: { selectedVoice },
            set: { savedVoicePreference = $0.rawValue }
        )
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    var body: some View {
        Form {
            Section("settings.screen.title") {
                NavigationLink {
                    VoicePreferenceSettingsView(selection: voicePreference)
                } label: {
                    HStack(spacing: 12) {
                        SettingsIcon(systemImage: "waveform", tint: .purple)
                        LabeledContent {
                            Text(selectedVoice.title)
                        } label: {
                            Text("settings.voicePreference.sectionTitle")
                        }
                    }
                }
                .accessibilityLabel("settings.voicePreference.sectionTitle")
                .accessibilityValue(Text(selectedVoice.title))
                .accessibilityIdentifier("settings.voicePreference")

                NavigationLink {
                    PrivacySettingsView()
                } label: {
                    SettingsLabel("voiceProfile.privacyPromise.title", systemImage: "hand.raised.fill", tint: .blue)
                }
                .accessibilityIdentifier("settings.privacy")

                NavigationLink {
                    ThemeSettingsView()
                } label: {
                    HStack(spacing: 12) {
                        SettingsIcon(systemImage: "paintpalette.fill", tint: themeColor)
                        LabeledContent {
                            Circle()
                                .fill(themeColor)
                                .frame(width: 22, height: 22)
                                .overlay {
                                    Circle().strokeBorder(Color.primary.opacity(0.16), lineWidth: 1)
                                }
                                .accessibilityHidden(true)
                        } label: {
                            Text("settings.theme.sectionTitle")
                        }
                    }
                }
                .accessibilityLabel("settings.theme.sectionTitle")
                .accessibilityValue(Text(themeColorDescription))
                .accessibilityIdentifier("settings.theme")
            }

            Section("about.app.title") {
                LabeledContent("about.app.version.label", value: appVersion)
                LabeledContent("about.app.analysisEngine.label", value: "PitcheeCore")
            }

            Section("settings.localTools.title") {
                NavigationLink {
                    LocalDiagnosticsView()
                } label: {
                    Label("settings.localDiagnostics.title", systemImage: "waveform.path.ecg")
                }
                NavigationLink {
                    LocalScoreStudyView()
                } label: {
                    Label("scoreStudy.settings.title", systemImage: "chart.bar.xaxis")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("about.screen.title")
        .navigationBarTitleDisplayMode(.large)
    }

    private var themeColor: Color {
        AppTheme.color(for: selectedVoice, customHex: customThemeColor)
    }

    private var themeColorDescription: String {
        customThemeColor.isEmpty
            ? String(localized: "settings.theme.followVoice")
            : String(localized: "settings.theme.customColor")
    }
}

private struct SettingsLabel: View {
    let title: LocalizedStringKey
    let systemImage: String
    let tint: Color

    init(_ title: LocalizedStringKey, systemImage: String, tint: Color) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
    }

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(systemImage: systemImage, tint: tint)
            Text(title)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct SettingsIcon: View {
    let systemImage: String
    let tint: Color
    @ScaledMetric(relativeTo: .body) private var scaledSize = 28

    private var size: CGFloat { min(scaledSize, 40) }

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.6, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(tint, in: RoundedRectangle(cornerRadius: size / 4, style: .continuous))
            .accessibilityHidden(true)
    }
}

struct VoicePreferenceSettingsView: View {
    @Binding var selection: VoicePreference

    var body: some View {
        Form {
            Section {
                Picker("settings.voicePreference.sectionTitle", selection: $selection) {
                    ForEach(VoicePreference.allCases) { option in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.title)
                                .foregroundStyle(.primary)
                            Text(option.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 4)
                        .tag(option)
                        .accessibilityIdentifier("settings.voicePreference.\(option.rawValue)")
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } footer: {
                Text("settings.voicePreference.autosaveNote")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("settings.voicePreference.sectionTitle")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ThemeSettingsView: View {
    @AppStorage(AppStorageKey.voicePreference) private var savedVoicePreference = ""
    @AppStorage(AppStorageKey.customThemeColor) private var customThemeColor = ""

    private var selectedVoice: VoicePreference {
        VoicePreference(legacyStoredValue: savedVoicePreference) ?? .undecided
    }

    private var themeColor: Color {
        AppTheme.color(for: selectedVoice, customHex: customThemeColor)
    }

    private var customColor: Binding<Color> {
        Binding(
            get: { themeColor },
            set: { customThemeColor = $0.appThemeHex ?? "" }
        )
    }

    var body: some View {
        Form {
            Section {
                ColorPicker(
                    "settings.theme.customColor",
                    selection: customColor,
                    supportsOpacity: false
                )
                .accessibilityIdentifier("settings.theme.customColor")

                Button {
                    customThemeColor = ""
                } label: {
                    HStack {
                        Text("settings.theme.reset")
                        Spacer()
                        if customThemeColor.isEmpty {
                            Image(systemName: "checkmark")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color.pitcheeAccent)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(customThemeColor.isEmpty)
                .accessibilityIdentifier("settings.theme.reset")
            } footer: {
                Text("settings.theme.description")
            }

            Section {
                HStack(spacing: 12) {
                    Circle()
                        .fill(themeColor)
                        .frame(width: 34, height: 34)
                        .overlay {
                            Circle().strokeBorder(Color.primary.opacity(0.16), lineWidth: 1)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("settings.theme.sectionTitle")
                            .font(.body.weight(.medium))
                        Text(LocalizedStringKey(customThemeColor.isEmpty
                            ? "settings.theme.followVoice"
                            : "settings.theme.customColor"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("settings.theme.sectionTitle")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySettingsView: View {
    @ScaledMetric(relativeTo: .body) private var iconSize = 22

    var body: some View {
        Form {
            Section {
                promise("voiceProfile.privacyPromise.onDevice.title", detail: "voiceProfile.privacyPromise.onDevice.description", symbol: "iphone")
                promise("voiceProfile.privacyPromise.recordingUsage.title", detail: "practice.audio.lifetime", symbol: "waveform")
                promise("voiceProfile.privacyPromise.userControl.title", detail: "voiceProfile.privacyPromise.userControl.description", symbol: "slider.horizontal.3")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("voiceProfile.privacyPromise.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func promise(_ title: LocalizedStringKey, detail: LocalizedStringKey, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: min(iconSize, 32)))
                .foregroundStyle(Color.pitcheeAccent)
                .frame(width: min(iconSize, 32), height: min(iconSize, 32))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview("Debug - About Settings") {
    NavigationStack { SettingsView() }
        .defaultAppStorage(DebugPreviewDefaults.store)
}

#Preview("Debug - Voice Preference Settings") {
    @Previewable @State var selection: VoicePreference = .feminine
    NavigationStack { VoicePreferenceSettingsView(selection: $selection) }
}

#Preview("Debug - Privacy Settings") {
    NavigationStack { PrivacySettingsView() }
}
#endif
