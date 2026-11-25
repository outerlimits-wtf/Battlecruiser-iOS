import MapKit
import SwiftUI
import DesignSystem
import PubDBClient
import PubDBModels

/// The pubs around the user, on a map or as a list.
///
/// Draws `PubsModel` and reports what the user does: a tapped pin or row goes
/// to `onSelect`, which the app uses to open the pub. It knows nothing of the
/// detail sheet, location permission or app lifecycle; the root owns those. The
/// list shows the map's current area, so it sits over the map rather than
/// replacing it: switching back keeps the map exactly where it was (D18).
public struct PubsMapScreen: View {
    let pubs: PubsModel
    let userCoordinate: Coordinate?
    let isLocationDenied: Bool
    let selectedID: String?
    let onSelect: (PubSummary) -> Void

    /// The map first, always (decision D18).
    @State var mode: PubsMode = .map
    /// Follows the user once a fix arrives; until then, and if refused, London.
    @State var position: MapCameraPosition = .userLocation(fallback: .region(PubsMapScreen.fallbackRegion))
    /// Whether the map has been brought to the user's first fix this launch.
    @State var hasCenteredOnUser = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    public init(
        pubs: PubsModel,
        userCoordinate: Coordinate?,
        isLocationDenied: Bool,
        selectedID: String?,
        onSelect: @escaping (PubSummary) -> Void
    ) {
        self.pubs = pubs
        self.userCoordinate = userCoordinate
        self.isLocationDenied = isLocationDenied
        self.selectedID = selectedID
        self.onSelect = onSelect
    }

    public var body: some View {
        ZStack {
            PubMap(
                position: $position,
                pubs: pubs.pubs,
                selectedID: selectedID,
                onAreaChange: { area in pubs.areaChanged(to: area) },
                onSelect: onSelect
            )
            .overlay(alignment: .bottomTrailing) {
                MapAttribution()
            }
            if mode == .list {
                PubListView(
                    pubs: pubs.pubs,
                    openCount: pubs.openCount,
                    notice: pubs.notice,
                    onGoToLondon: goToLondon,
                    onRetry: pubs.refresh,
                    onSelect: onSelect,
                    onRefresh: {
                        pubs.refresh()
                        await pubs.loadTask?.value
                    }
                )
                .background(.background)
            }
        }
        .overlay(alignment: .top) {
            StatusBanner(
                pubs: pubs,
                isLocationDenied: isLocationDenied,
                showsNotice: mode == .map,
                onGoToLondon: goToLondon
            )
        }
        .safeAreaInset(edge: .top) {
            ModePicker(mode: $mode)
        }
        .task {
            // Last session's pubs first, marked with their age, so the screen
            // is never empty while the first fetch is under way.
            await pubs.loadCached()
            // The map normally reports its area as soon as it appears. If it
            // hasn't after a second, show London rather than an empty map.
            try? await Task.sleep(for: .seconds(1))
            pubs.loadIfIdle(in: BoundingBox(Self.fallbackRegion))
        }
        .onChange(of: userCoordinate, initial: true) { _, coordinate in
            pubs.userLocationChanged(to: coordinate)
            centerOnUserIfNeeded(at: coordinate)
        }
        .task(id: Freshness.refreshInterval(for: pubs.pubs)) {
            await pubs.refreshPeriodically(every: Freshness.refreshInterval(for: pubs.pubs))
        }
    }
}

#Preview("Live data") {
    PubsMapScreen(
        pubs: PubsModel(source: PubDBClient()),
        userCoordinate: nil,
        isLocationDenied: false,
        selectedID: nil,
        onSelect: { _ in }
    )
}
