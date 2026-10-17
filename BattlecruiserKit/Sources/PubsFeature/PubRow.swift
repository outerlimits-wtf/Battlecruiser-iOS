import SwiftUI
import DesignSystem
import PubDBModels

/// One pub in the list: the same ship and colours as its map pin, then what
/// matters at closing time. Every string is the server's.
struct PubRow: View {
    let pub: PubSummary

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ShipPin(emphasis: emphasis)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(pub.name)
                        .font(.headline)
                    Spacer(minLength: 8)
                    if let distance = pub.distance {
                        Text(distance.label)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                OpenPill(pub: pub)
                if !details.isEmpty {
                    Text(details)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        // Fill the row and make all of it tappable, gaps included; a plain-style
        // button otherwise only responds to the parts that draw something.
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        // Closed pubs stay in the list but step back, like their pins.
        .opacity(emphasis == .closed ? 0.6 : 1)
        .accessibilityElement(children: .combine)
    }

    private var emphasis: PinEmphasis {
        PinEmphasis(pub)
    }

    /// "🚪 Out 24:40 · Guinness £6.20", whichever of the two exist.
    private var details: String {
        var parts: [String] = []
        if let tonight = pub.tonight {
            parts.append("\(tonight.symbol.emoji) \(tonight.label)")
        }
        if let guinness = pub.guinness {
            parts.append("Guinness \(guinness.formatted)")
        }
        if !pub.status.serving {
            parts.append(pub.status.label)
        }
        return parts.joined(separator: " · ")
    }
}
