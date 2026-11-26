import SwiftUI
import DesignSystem
import PubDBModels

/// Been here, Reviews, Added: three tiles.
struct StatTiles: View {
    let stats: Profile.Stats

    var body: some View {
        HStack(spacing: Metrics.s) {
            tile("Been here", stats.visited)
            tile("Reviews", stats.reviews)
            tile("Added", stats.contributions)
        }
    }

    private func tile(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(value)").font(Typography.title).foregroundStyle(Palette.ink)
            Text(title).font(Typography.secondary).foregroundStyle(Palette.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Metrics.m)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.cardRadius))
        .accessibilityElement(children: .combine)
    }
}
