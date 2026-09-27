//
//  SettingsView.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/18.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(AppStorageKey.voicePreference) private var savedVoicePreference = ""

    private var selectedVoice: VoicePreference {
        VoicePreference(rawValue: savedVoicePreference) ?? .undecided
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("settings.voicePreference.headline.title")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                    Text("settings.voicePreference.headline.subtitle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("settings.voicePreference.sectionTitle").font(.headline)
                    ForEach(VoicePreference.allCases) { option in
                        VoicePreferenceCard(option: option, isSelected: selectedVoice == option) {
                            savedVoicePreference = option.rawValue
                        }
                    }
                    Text("settings.voicePreference.autosaveNote")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }

                PrivacyPromiseView()
            }
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .padding(24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("settings.screen.title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview("Debug - Settings") {
    NavigationStack { SettingsView() }
        .defaultAppStorage(DebugPreviewDefaults.store)
}
#endif
