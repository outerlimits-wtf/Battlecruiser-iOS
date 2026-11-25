import SwiftUI

/// The web's shadows: `card` for resting cards, `float` for things over the map.
public enum Elevation {
    case card
    case float
}

extension View {
    public func elevation(_ level: Elevation) -> some View {
        modifier(ElevationModifier(level: level))
    }
}

private struct ElevationModifier: ViewModifier {
    let level: Elevation
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let dark = colorScheme == .dark
        switch level {
        case .card:
            content
                .shadow(color: .black.opacity(dark ? 0.5 : 0.16), radius: 1.5, y: 1)
        case .float:
            content
                .shadow(color: .black.opacity(dark ? 0.55 : 0.2), radius: 4, y: 2)
        }
    }
}
