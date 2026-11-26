import SwiftUI

/// Light, dark, or whatever the phone is set to. Picked in Me → Appearance.
public enum ThemePreference: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    /// Where the choice is kept (`UserDefaults`, via `@AppStorage`).
    public static let storageKey = "themePreference"

    public var id: String { rawValue }

    /// The web's labels.
    public var label: String {
        switch self {
        case .system: "🌓 System"
        case .light: "☀️ Light"
        case .dark: "🌙 Dark"
        }
    }

    /// For `.preferredColorScheme(_:)`; nil follows the phone.
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
