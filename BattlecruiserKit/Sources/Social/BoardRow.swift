import SwiftUI
import DesignSystem
import PubDBModels

/// Rank, photo, name and detail; the ranked figure and whether it's open on the right.
struct BoardRow: View {
    let entry: Board.Entry

    var body: some View {
        HStack(spacing: Metrics.m) {
            RankBadge(entry.rank)
            PubPhoto(entry.pub.photo, name: entry.pub.name, emoji: entry.pub.amenity.symbol.emoji, size: .thumbnail)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.thumbRadius))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.pub.name).font(Typography.rowTitle).foregroundStyle(Palette.ink).lineLimit(1)
                Text([entry.detail, entry.pub.distance?.label].compactMap { $0 }.joined(separator: " · "))
                    .font(Typography.secondary)
                    .foregroundStyle(Palette.inkMuted)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.value).font(Typography.rowTitle).foregroundStyle(Palette.beer)
                HoursPill(entry.pub.open).font(Typography.secondary)
            }
        }
        .padding(.horizontal, Metrics.l)
        .padding(.vertical, Metrics.s)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Shows the pub")
    }
}
