import SwiftUI
import DesignSystem
import PubDBModels

/// Brand, name, what it is, whether it's open, and where.
struct PanelHeader: View {
    let summary: PubSummary
    let city: String?
    /// The venue kind's note from `/meta` (gastropub's), shown behind an ⓘ.
    let kindNote: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let brand = summary.brand {
                Text(brand).font(Typography.secondary).foregroundStyle(Palette.inkMuted)
            }
            Text(summary.name)
                .font(Typography.title)
                .foregroundStyle(Palette.ink)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 0) {
                Text(PanelLines.summary(summary))
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
}

/// The header's joined lines, as the web builds them.
enum PanelLines {
    /// "8.4 ★ (11) · Gastropub · Balham · Guinness £6.20".
    static func summary(_ pub: PubSummary) -> String {
        var parts: [String] = []
        if let rating = pub.rating {
            // S7 asks the server for a ready-made `ratingLabel`.
            parts.append("\(rating.formatted(.number.precision(.fractionLength(1)))) ★ (\(pub.reviewCount))")
        }
        parts.append(pub.amenity.label)
        if let area = pub.area { parts.append(area) }
        if let guinness = pub.guinness { parts.append("Guinness \(guinness.formatted)") }
        return parts.joined(separator: " · ")
    }

    /// "77 Bedford Hill, London, SW12 9HD". S7 asks for `addressLine`.
    static func address(_ pub: PubSummary, city: String?) -> String? {
        let parts = [pub.address, city, pub.postcode].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}
