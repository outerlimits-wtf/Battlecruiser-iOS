import SwiftUI
import PubDBModels

/// A level in full: the badge, its line, XP, and how far to the next.
public struct LevelProgress: View {
    private let level: Level

    public init(_ level: Level) {
        self.level = level
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                LevelBadge(level)
                Spacer()
                if let xp = level.xpLabel {
                    Text(xp).font(Typography.secondary).foregroundStyle(Palette.inkMuted)
                }
            }
            if let line = level.line {
                Text(line).font(Typography.body.italic()).foregroundStyle(Palette.inkMuted)
            }
            if let next = level.next {
                ProgressView(value: min(max(level.progress ?? 0, 0), 1))
                    .tint(Palette.beer)
                Text(next.remainingLabel).font(Typography.secondary).foregroundStyle(Palette.inkFaint)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
