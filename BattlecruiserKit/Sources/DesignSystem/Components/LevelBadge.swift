import SwiftUI
import PubDBModels

/// A level as a small pill: "🍺 Regular".
public struct LevelBadge: View {
    private let level: Level

    public init(_ level: Level) {
        self.level = level
    }

    public var body: some View {
        Text([level.emoji, level.name].compactMap { $0 }.joined(separator: " "))
            .font(Typography.secondary.weight(.semibold))
            .foregroundStyle(Palette.beer)
            .padding(.horizontal, Metrics.s)
            .padding(.vertical, 2)
            .background(Palette.beerSoft, in: Capsule())
            .accessibilityLabel("Level: \(level.name)")
    }
}
