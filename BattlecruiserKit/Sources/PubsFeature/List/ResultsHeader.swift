import SwiftUI
import DesignSystem

/// The top of the sheet when it holds the list, visible even at peek:
/// "35 pubs · ● 12 open", then what the list is of.
struct ResultsHeader: View {
    let count: Int
    let openCount: Int
    let isLoading: Bool
    let knowsLocation: Bool
    /// Searching or "everywhere": the list isn't limited to the map.
    let isEverywhere: Bool
    let onTurnOffEverywhere: (() -> Void)?

    var body: some View {
        HStack(alignment: .top) {
            lines
            Spacer(minLength: Metrics.s)
            if let onTurnOffEverywhere {
                Button("🌍 Everywhere ✕", action: onTurnOffEverywhere)
                    .buttonStyle(ChipStyle(isSelected: true))
                    .accessibilityLabel("Stop searching everywhere")
            }
        }
        .padding(.horizontal, Metrics.l)
        .padding(.bottom, Metrics.s)
    }

    private var lines: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 0) {
                if isLoading && count == 0 {
                    Text("Searching…")
                } else {
                    Text("\(count) \(count == 1 ? "pub" : "pubs")")
                    if openCount > 0 {
                        Text(" · ")
                        Text("● \(openCount) open").foregroundStyle(Palette.good)
                    }
                }
            }
            .font(Typography.rowTitle)
            .foregroundStyle(Palette.ink)
            Text(scope)
                .font(Typography.secondary)
                .foregroundStyle(Palette.inkMuted)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var scope: String {
        if isEverywhere { return "Across everywhere we know" }
        return knowsLocation ? "Near you, open ones first" : "In the area you are looking at"
    }
}
