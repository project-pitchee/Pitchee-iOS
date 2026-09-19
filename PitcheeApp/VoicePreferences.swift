//
//  VoicePreferences.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/18.
//

import SwiftUI

enum VoicePreference: String, CaseIterable, Identifiable {
    // Keep the existing stored values so earlier selections are preserved.
    case masculine = "男性向声音"
    case feminine = "女性向声音"
    case undecided = "暂不确定"

    var id: String { rawValue }

    var detail: String {
        switch self {
        case .masculine: "探索更低沉、厚实的声音"
        case .feminine: "探索更明亮、柔和的声音"
        case .undecided: "先了解自己的声音，慢慢找到方向"
        }
    }
}

struct VoicePreferenceCard: View {
    let option: VoicePreference
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStringKey(option.rawValue))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(LocalizedStringKey(option.detail))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.5))
                    .accessibilityHidden(true)
            }
            .multilineTextAlignment(.leading)
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .background(
                isSelected ? Color.accentColor.opacity(0.07) : Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 20)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

struct PrivacyPromiseView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("隐私保护承诺", systemImage: "lock.shield")
                .font(.headline)
            promise("只在设备上分析", detail: "声音分析在本机完成，录音不会上传到服务器，也不会共享给第三方。", symbol: "iphone")
            promise("录音仅用于本次分析", detail: "分析结束后清理临时录音，历史记录仅保存分析结果。", symbol: "waveform")
            promise("选择始终由你掌控", detail: "声音偏好可随时修改。麦克风权限可在系统设置中关闭。", symbol: "slider.horizontal.3")
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
    }

    private func promise(_ title: LocalizedStringKey, detail: LocalizedStringKey, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
