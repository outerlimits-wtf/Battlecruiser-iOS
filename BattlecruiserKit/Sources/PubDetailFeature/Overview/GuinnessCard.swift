import SwiftUI
import DesignSystem
import PubDBModels

/// "PRICE OF A GUINNESS": the latest reported price and how old it is. Tap
/// for every report on a graph.
struct GuinnessCard: View {
    let guinness: Guinness
    let history: PriceHistory?
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.m) {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack(spacing: Metrics.m) {
                    Image(uiImage: BrandImage.guinness)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 32)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        SectionHeader("Price of a Guinness")
                        HStack(alignment: .firstTextBaseline, spacing: Metrics.s) {
                            Text(guinness.formatted)
                                .font(Typography.title)
                                .foregroundStyle(Palette.ink)
                            Text(guinness.agoLabel)
                                .font(Typography.secondary)
                                .foregroundStyle(Palette.inkMuted)
                        }
                    }
                    Spacer()
                    if canExpand {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(Palette.inkFaint)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(!canExpand)
            .accessibilityHint(canExpand ? "Shows every price reported" : "")
            if isExpanded, let history {
                PriceGraph(points: history.points)
            }
        }
        .padding(Metrics.l)
        .background(Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: Metrics.cardRadius))
    }

    private var canExpand: Bool {
        (history?.points.count ?? 0) >= 2
    }
}
