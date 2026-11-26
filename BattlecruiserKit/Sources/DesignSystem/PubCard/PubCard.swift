import SwiftUI
import PubDBModels

/// One pub in a list, as the web's `PubCard`: photo, name, what it is and what
/// it costs, whether it's open, and what it has. Shut pubs fade back.
public struct PubCard: View {
    private let pub: PubSummary
    private let isSelected: Bool
    private let isVisited: Bool

    /// - Parameter isVisited: On the person's Been here list: a tick by the name.
    public init(_ pub: PubSummary, isSelected: Bool = false, isVisited: Bool = false) {
        self.pub = pub
        self.isSelected = isSelected
        self.isVisited = isVisited
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Metrics.m) {
            PubPhoto(pub.photo, name: pub.name, emoji: pub.amenity.symbol.emoji, size: .thumbnail)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.thumbRadius))
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(pub.name)
                        .font(Typography.rowTitle)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                    if isVisited {
                        Image(systemName: "checkmark")
                            .font(Typography.secondary.weight(.bold))
                            .foregroundStyle(Palette.good.opacity(0.7))
                            .accessibilityLabel("Been here")
                    }
                }
                summaryLine
                    .font(Typography.body)
                    .foregroundStyle(Palette.inkMuted)
                    .lineLimit(2)
                openLine
                if let quote = pub.quote {
                    Text("“\(quote.text)”")
                        .font(Typography.secondary.italic())
                        .foregroundStyle(Palette.inkMuted)
                        .lineLimit(1)
                }
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

    private var summaryLine: Text {
        let line = Text(PubCardLines.summary(pub))
        guard let guinness = pub.guinness else { return line }
        return line + Text(PubCardLines.separator) + GuinnessText.text(guinness.formatted)
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
