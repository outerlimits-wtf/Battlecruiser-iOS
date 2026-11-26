import SwiftUI

/// Pub data comes from OpenStreetMap (ODbL), which requires this credit
/// wherever it is shown, including on Apple's map. Fine print in the corner
/// opposite Apple's own "Legal" label and styled to match it: small secondary
/// text with no background, so it reads as a map credit rather than a notice
/// (decision D25). The detail sheet sits over the map, so this covers it too.
struct MapAttribution: View {
    var body: some View {
        Text("© OpenStreetMap contributors")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.trailing, 8)
            .padding(.bottom, 4)
    }
}
