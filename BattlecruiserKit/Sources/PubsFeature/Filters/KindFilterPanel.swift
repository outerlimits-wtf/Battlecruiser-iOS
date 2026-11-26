import SwiftUI
import DesignSystem
import PubDBClient
import PubDBModels

/// "KIND OF PLACE": proper pubs, bars, or both; or "TYPE", any of the venue
/// kinds from `/meta` (taproom, oddity…), which cross both groups.
struct KindFilterPanel: View {
    @Binding var query: PubQuery
    let kinds: [VenueKind]

    var body: some View {
        SectionHeader("Kind of place")
        ChipFlow {
            chip("🍺 Proper pubs", amenity: "pub")
            chip("🍸 Bars", amenity: "bar")
            chip("🍻 Both", amenity: nil)
        }
        Text("PubDB shows proper pubs by default. Bars are here when you want them; they just do not get the beer icon.")
            .font(Typography.secondary)
            .foregroundStyle(Palette.inkMuted)
        if !kinds.isEmpty {
            SectionHeader("Type")
            ChipFlow {
                ForEach(kinds) { kind in
                    let isPicked = query.kinds.contains(kind.key)
                    Button("\(kind.symbol.emoji) \(kind.label)") {
                        if isPicked { query.kinds.remove(kind.key) } else { query.kinds.insert(kind.key) }
                    }
                    .buttonStyle(ChipStyle(isSelected: isPicked))
                    .accessibilityLabel(kind.label)
                }
            }
            Text("Pick as many as you like: any of them will do.")
                .font(Typography.secondary)
                .foregroundStyle(Palette.inkMuted)
        }
    }

    /// Picking a group drops any types, which would override it.
    private func chip(_ title: String, amenity: String?) -> some View {
        Button(title) {
            query.amenity = amenity
            query.kinds = []
        }
        .buttonStyle(ChipStyle(isSelected: query.kinds.isEmpty && query.amenity == amenity))
    }
}
