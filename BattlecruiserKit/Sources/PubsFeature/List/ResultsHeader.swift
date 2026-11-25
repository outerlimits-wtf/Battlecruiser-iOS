import SwiftUI
import DesignSystem

/// The top of the sheet when it holds the list, visible even at peek:
/// "35 pubs · ● 12 open", then what the list is of.
struct ResultsHeader: View {
    let count: Int
    let openCount: Int
    let isLoading: Bool
    let knowsLocation: Bool

    var body: some View {
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
            Text(knowsLocation ? "Near you, open ones first" : "In the area you are looking at")
                .font(Typography.secondary)
                .foregroundStyle(Palette.inkMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Metrics.l)
        .padding(.bottom, Metrics.s)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
