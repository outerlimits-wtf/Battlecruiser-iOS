import SwiftUI
import DesignSystem
import PubDBClient
import PubDBModels

/// The card under the pill row for the open panel, with "Done" at the bottom.
struct FilterPanelCard: View {
    let panel: FilterPanel
    @Binding var query: PubQuery
    let meta: Meta?
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.m) {
            switch panel {
            case .kind: KindFilterPanel(query: $query, kinds: meta?.venueKinds ?? [])
            case .hours: HoursFilterPanel(query: $query, weekdays: meta?.weekdays ?? [])
            case .features: FeaturesFilterPanel(query: $query, features: meta?.features ?? [])
            case .rating: RatingFilterPanel(query: $query)
            case .guinness: GuinnessFilterPanel(query: $query)
            }
            HStack {
                Spacer()
                Button("Done", action: onDone).buttonStyle(ChipStyle(isSelected: true))
            }
        }
        .padding(Metrics.l)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.cardRadius))
        .elevation(.float)
        .padding(.horizontal, Metrics.m)
    }
}
