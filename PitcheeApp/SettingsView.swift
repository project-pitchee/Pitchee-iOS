//
//  SettingsView.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/18.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("pitchee.voice.preference") private var savedVoicePreference = ""

    private var selectedVoice: VoicePreference {
        VoicePreference(rawValue: savedVoicePreference) ?? .undecided
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("找到你的声音方向")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                    Text("可以有明确的目标，也可以先探索。你随时都能回来调整。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("声音偏好").font(.headline)
                    ForEach(VoicePreference.allCases) { option in
                        VoicePreferenceCard(option: option, isSelected: selectedVoice == option) {
                            savedVoicePreference = option.rawValue
                        }
                    }
                    Text("选择会自动保存，用于记录你的练习方向。当前偏好不会改变分析评分。")
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
        .navigationTitle("偏好与隐私")
        .navigationBarTitleDisplayMode(.inline)
    }
}
