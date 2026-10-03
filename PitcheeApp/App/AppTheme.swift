//
//  AppTheme.swift
//  Pitchee
//

import SwiftUI
import UIKit

/// The app-wide theme color. Voice direction supplies the default, while an
/// optional user-selected color takes precedence.
enum AppTheme {
    static func color(for preference: VoicePreference, customHex: String) -> Color {
        Color(hex: customHex) ?? defaultColor(for: preference)
    }

    static func defaultColor(for preference: VoicePreference) -> Color {
        switch preference {
        case .masculine:
            return Color(red: 0.16, green: 0.42, blue: 0.90)
        case .feminine:
            return Color(red: 0.91, green: 0.25, blue: 0.52)
        case .undecided:
            return Color(red: 0.16, green: 0.42, blue: 0.90)
        }
    }
}

extension Color {
    /// Resolves the current app accent for places that need a concrete `Color`
    /// value (for example, Charts and Canvas). Views also receive the same
    /// value through the root `.tint` modifier.
    static var pitcheeAccent: Color {
        let defaults = UserDefaults.standard
        let preference = VoicePreference(
            legacyStoredValue: defaults.string(forKey: AppStorageKey.voicePreference) ?? ""
        ) ?? .undecided
        return AppTheme.color(
            for: preference,
            customHex: defaults.string(forKey: AppStorageKey.customThemeColor) ?? ""
        )
    }

    init?(hex: String) {
        let value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard value.count == 6 || value.count == 8,
              let number = UInt64(value, radix: 16) else {
            return nil
        }

        let red = Double((number >> (value.count == 8 ? 24 : 16)) & 0xFF) / 255
        let green = Double((number >> (value.count == 8 ? 16 : 8)) & 0xFF) / 255
        let blue = Double((number >> (value.count == 8 ? 8 : 0)) & 0xFF) / 255
        let alpha = value.count == 8 ? Double(number & 0xFF) / 255 : 1
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    /// Returns a stable sRGB representation suitable for `UserDefaults`.
    var appThemeHex: String? {
        var red = CGFloat.zero
        var green = CGFloat.zero
        var blue = CGFloat.zero
        var alpha = CGFloat.zero
        guard UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        return String(
            format: "#%02X%02X%02X",
            Int((red * 255).rounded()),
            Int((green * 255).rounded()),
            Int((blue * 255).rounded())
        )
    }
}
