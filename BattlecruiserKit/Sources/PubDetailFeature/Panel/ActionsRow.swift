import SwiftUI
import AppEnvironment
import DesignSystem
import PubDBClient
import PubDBModels

/// Directions, then Save and Been here: the web's round buttons. Signed out,
/// Save and Been here are left off and a line says why.
struct ActionsRow: View {
    let summary: PubSummary
    let context: PanelContext
    @State private var isShowingDirections = false

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.s) {
            HStack(spacing: Metrics.m) {
                ActionButton(title: "Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill", isPrimary: true) {
                    isShowingDirections = true
                }
                if context.session.isSignedIn {
                    mark(.watchlist, on: "Saved", off: "Save", image: "bookmark")
                    mark(.visited, on: "Been here", off: "Been here", image: "checkmark.circle")
                }
                Spacer()
            }
            if context.mustSignIn && context.session.offersSignIn {
                Text("Sign in from the Me tab to save pubs, tick them off and add what you know.")
                    .font(Typography.secondary)
                    .foregroundStyle(Palette.inkMuted)
            }
        }
        .sheet(isPresented: $isShowingDirections) {
            GetThereSheet(
                name: summary.name,
                links: DirectionsLink.all(name: summary.name, latitude: summary.lat, longitude: summary.lon)
            )
        }
    }

    private func mark(_ list: SavedList, on: String, off: String, image: String) -> some View {
        let isOn = context.marks.contains(summary.id, on: list)
        return ActionButton(title: isOn ? on : off, systemImage: isOn ? image + ".fill" : image, isOn: isOn) {
            Task { await context.marks.toggle(summary.id, on: list) }
        }
    }
}
