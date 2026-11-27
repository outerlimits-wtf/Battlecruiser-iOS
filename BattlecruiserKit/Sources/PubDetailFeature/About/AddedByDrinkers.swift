import SwiftUI
import DesignSystem
import PubDBModels

/// "ADDED BY DRINKERS": every fact people added, ✕ on the ones you may take
/// back, as the web's Fix mode shows them.
struct AddedByDrinkers: View {
    let contributions: [Contribution]
    let onRemove: (Contribution) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.m) {
            SectionHeader("Added by drinkers (\(contributions.count))")
            if contributions.isEmpty {
                Text("Nothing yet. Everything on this page came off the scrape.")
                    .font(Typography.body)
                    .foregroundStyle(Palette.inkMuted)
            }
            ForEach(contributions) { contribution in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contribution.fieldLabel.uppercased())
                            .font(Typography.sectionHeader)
                            .foregroundStyle(Palette.inkMuted)
                        Text(contribution.displayValue).font(Typography.body).foregroundStyle(Palette.ink)
                        if contribution.attribution.kind != "importer" {
                            Text("\(contribution.attribution.label) · \(contribution.createdAtLabel)")
                                .font(Typography.secondary)
                                .foregroundStyle(Palette.inkFaint)
                        }
                    }
                    Spacer()
                    if contribution.canRemove {
                        Button { onRemove(contribution) } label: {
                            Image(systemName: "xmark").frame(width: Metrics.minTap, height: Metrics.minTap)
                        }
                        .foregroundStyle(Palette.inkMuted)
                        .accessibilityLabel("Take back \(contribution.fieldLabel)")
                    }
                }
                .accessibilityElement(children: .contain)
            }
            if contributions.contains(where: \.canRemove) {
                Text("Taking one out puts back whatever it was sitting on top of: an earlier report, or what the scrape found.")
                    .font(Typography.secondary)
                    .foregroundStyle(Palette.inkFaint)
            }
        }
    }
}
