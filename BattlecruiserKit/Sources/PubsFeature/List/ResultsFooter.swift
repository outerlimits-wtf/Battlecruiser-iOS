import SwiftUI
import DesignSystem
import PubDBClient

/// Under the last card: whether the list was cut short, and the OSM credit
/// (a licence condition wherever OSM data is shown).
struct ResultsFooter: View {
    let count: Int

    var body: some View {
        VStack(spacing: Metrics.s) {
            // S1 asks the server for a `truncated` flag instead of this guess.
            if count >= PubDBClient.defaultLimit {
                Text("Showing the closest \(count). Zoom in or add a filter to see the rest.")
                    .font(Typography.secondary)
                    .foregroundStyle(Palette.inkMuted)
                    .multilineTextAlignment(.center)
            }
            Text("Pub data © OpenStreetMap contributors")
                .font(Typography.micro)
                .foregroundStyle(Palette.inkFaint)
        }
        .padding(Metrics.l)
        .frame(maxWidth: .infinity)
    }
}
