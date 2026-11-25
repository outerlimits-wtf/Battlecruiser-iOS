import SwiftUI
import DesignSystem
import PubDBClient

/// "KIND OF PLACE": proper pubs, bars, or both.
struct KindFilterPanel: View {
    @Binding var query: PubQuery

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
    }

    private func chip(_ title: String, amenity: String?) -> some View {
        Button(title) { query.amenity = amenity }
            .buttonStyle(ChipStyle(isSelected: query.amenity == amenity))
    }
}
