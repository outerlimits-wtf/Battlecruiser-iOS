import SwiftUI
import DesignSystem
import PubDBModels

/// Name and brand, what it is, whether it's open, and where.
struct PanelHeader: View {
    let summary: PubSummary
    let city: String?
    /// The venue kind's note from `/meta` (gastropub's), shown behind an ⓘ.
    let kindNote: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            nameLine
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 0) {
                summaryLine
                    .font(Typography.body)
                    .foregroundStyle(Palette.inkMuted)
                if let kindNote {
                    InfoTip(kindNote)
                }
            }
            if !summary.status.serving {
                Text(summary.status.label)
                    .font(Typography.body.weight(.semibold))
                    .foregroundStyle(Palette.warn)
            } else if summary.open.state != .unknown {
                HoursPill(summary.open)
            }
            if let address = PanelLines.address(summary, city: city) {
                Text(address).font(Typography.body).foregroundStyle(Palette.inkMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The name, then the operator (when known) a touch smaller and lighter,
    /// running on after it and wrapping with it.
    private var nameLine: Text {
        let name = Text(summary.name).font(Typography.title).foregroundStyle(Palette.ink)
        guard let brand = summary.brand else { return name }
        return name + Text("  " + brand).font(Typography.subtitle).foregroundStyle(Palette.inkMuted)
    }

    private var summaryLine: Text {
        var line = Text(PanelLines.summary(summary))
        if let rating = summary.rating {
            line = RatingText.text(rating, reviewCount: summary.reviewCount) + Text(" · ") + line
        }
        guard let guinness = summary.guinness else { return line }
        return line + Text(" · ") + GuinnessText.text(guinness.formatted)
    }
}

/// The header's joined lines, as the web builds them.
enum PanelLines {
    /// "Gastropub · Balham". The rating (with its coloured star) goes before
    /// it and the Guinness price, with its icon, after.
    static func summary(_ pub: PubSummary) -> String {
        var parts = [pub.amenity.label]
        if let area = pub.area { parts.append(area) }
        return parts.joined(separator: " · ")
    }

    /// "77 Bedford Hill, London, SW12 9HD". S7 asks for `addressLine`.
    static func address(_ pub: PubSummary, city: String?) -> String? {
        let parts = [pub.address, city, pub.postcode].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}
