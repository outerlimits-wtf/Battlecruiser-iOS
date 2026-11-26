import SwiftUI
import DesignSystem

/// A row leading to a page, as in the web's menu: emoji, title, blurb, ›.
public struct MenuRow: View {
    let emoji: String
    let title: String
    let blurb: String

    public init(emoji: String, title: String, blurb: String) {
        self.emoji = emoji
        self.title = title
        self.blurb = blurb
    }

    public var body: some View {
        HStack(spacing: Metrics.m) {
            Text(emoji).font(.title3).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Typography.rowTitle).foregroundStyle(Palette.ink)
                Text(blurb).font(Typography.secondary).foregroundStyle(Palette.inkMuted)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Palette.inkFaint)
        }
        .padding(Metrics.m)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.cardRadius))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
