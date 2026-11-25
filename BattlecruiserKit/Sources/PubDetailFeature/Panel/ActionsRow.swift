import SwiftUI
import DesignSystem
import PubDBModels

/// Directions, then (once signed in, Phase E) Save, Been here and Fix.
struct ActionsRow: View {
    let summary: PubSummary
    @State private var isShowingDirections = false

    var body: some View {
        HStack(spacing: Metrics.m) {
            ActionButton(title: "Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill", isPrimary: true) {
                isShowingDirections = true
            }
            Spacer()
        }
        .sheet(isPresented: $isShowingDirections) {
            GetThereSheet(
                name: summary.name,
                links: DirectionsLink.all(name: summary.name, latitude: summary.lat, longitude: summary.lon)
            )
        }
    }
}
