import SwiftUI
import DesignSystem
import PubDBModels

/// "NEARBY": the closest other pubs as small cards; tap one to open it.
struct NearbyStrip: View {
    let pubs: [PubSummary]
    let onSelect: (PubSummary) -> Void

    var body: some View {
        if !pubs.isEmpty {
            VStack(alignment: .leading, spacing: Metrics.s) {
                SectionHeader("Nearby")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: Metrics.m) {
                        ForEach(pubs) { pub in
                            Button { onSelect(pub) } label: { card(pub) }
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func card(_ pub: PubSummary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            PubPhoto(pub.photo, name: pub.name, emoji: pub.amenity.symbol.emoji, size: .thumbnail)
                .frame(width: 144, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.thumbRadius))
            Text(pub.name)
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
            Text(detail(pub))
                .font(Typography.secondary)
                .foregroundStyle(Palette.inkMuted)
                .lineLimit(1)
        }
        .frame(width: 144, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func detail(_ pub: PubSummary) -> String {
        // S7 asks the server for a ready-made `ratingLabel`.
        let rating = pub.rating.map { "\($0.formatted(.number.precision(.fractionLength(1)))) ★" } ?? "No reviews"
        return pub.guinness.map { "\(rating) · \($0.formatted)" } ?? rating
    }
}
