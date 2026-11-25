import SwiftUI
import PubDBModels

/// One pub in a list, as the web's `PubCard`: photo, name, what it is and what
/// it costs, whether it's open, and what it has. Shut pubs fade back.
public struct PubCard: View {
    private let pub: PubSummary
    private let isSelected: Bool

    public init(_ pub: PubSummary, isSelected: Bool = false) {
        self.pub = pub
        self.isSelected = isSelected
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Metrics.m) {
            PubPhoto(pub.photo, name: pub.name, emoji: pub.amenity.symbol.emoji, size: .thumbnail)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.thumbRadius))
            VStack(alignment: .leading, spacing: 3) {
                Text(pub.name)
                    .font(Typography.rowTitle)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                Text(PubCardLines.summary(pub))
                    .font(Typography.body)
                    .foregroundStyle(Palette.inkMuted)
                    .lineLimit(2)
                openLine
                if let features = PubCardLines.features(pub) {
                    Text(features)
                        .font(Typography.secondary)
                        .foregroundStyle(Palette.inkFaint)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(Metrics.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Palette.beerSoft : .clear)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.surfaceSunken).frame(height: 1)
        }
        .opacity(PubCardLines.isShut(pub) ? 0.6 : 1)
        .saturation(PubCardLines.isShut(pub) ? 0 : 1)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var openLine: some View {
        if !pub.status.serving {
            Text(PubCardLines.status(pub.status))
                .font(Typography.body)
                .foregroundStyle(Palette.inkFaint)
        } else {
            HStack(spacing: 0) {
                HoursPill(pub.open)
                if let extras = PubCardLines.extras(pub) {
                    Text(PubCardLines.separator + extras)
                        .font(Typography.body)
                        .foregroundStyle(Palette.inkMuted)
                }
            }
            .lineLimit(1)
        }
    }
}
