import MapKit
import SwiftUI
import UIKit
import DesignSystem
import PubDBClient
import PubDetailFeature
import UserLocation

/// The app's main screen: the pubs around the user, on a map or as a list.
///
/// Owns the screen's state (pubs, location, the selected pub) and connects
/// them: the user's position goes to the API for distances, the map's area
/// drives fetching, and a tapped pin or row opens its detail sheet. The list
/// shows the map's current area, so it sits over the map rather than replacing
/// it: switching back keeps the map exactly where it was (decision D18).
public struct PubsMapScreen: View {
    enum Mode: String, CaseIterable, Identifiable {
        case map = "Map"
        case list = "List"

        var id: Self {
            self
        }

        var systemImage: String {
            switch self {
            case .map:
                "map"
            case .list:
                "list.bullet"
            }
        }
    }

    /// Where the map opens without the user's location: central London, where
    /// all the data is.
    static let fallbackRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.5098, longitude: -0.1257),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )

    @State private var pubs: PubsModel
    @State private var detail: PubDetailModel
    @State private var location = LocationModel()
    /// The map first, always (decision D18).
    @State private var mode: Mode = .map
    /// Follows the user once a fix arrives; until then, and if refused, London.
    @State private var position: MapCameraPosition = .userLocation(fallback: .region(PubsMapScreen.fallbackRegion))
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    /// - Parameter source: Where pubs and their details come from; the app
    ///   passes its `PubDBClient`, which is both.
    public init(source: any PubSource & PubDetailSource) {
        _pubs = State(initialValue: PubsModel(source: source))
        _detail = State(initialValue: PubDetailModel(source: source))
    }

    public var body: some View {
        ZStack {
            PubMap(
                position: $position,
                pubs: pubs.pubs,
                selectedID: detail.selected?.id,
                onAreaChange: { area in
                    pubs.areaChanged(to: area)
                },
                onSelect: { pub in
                    detail.select(pub, near: userCoordinate)
                }
            )
            .overlay(alignment: .bottom) {
                attribution
            }
            if mode == .list {
                PubListView(
                    pubs: pubs.pubs,
                    openCount: pubs.openCount,
                    notice: pubs.notice,
                    onGoToLondon: goToLondon,
                    onRetry: pubs.refresh,
                    onSelect: { pub in
                        detail.select(pub, near: userCoordinate)
                    },
                    onRefresh: {
                        pubs.refresh()
                        await pubs.loadTask?.value
                    }
                )
                .background(.background)
            }
        }
        .overlay(alignment: .top) {
            statusBanner
        }
        .safeAreaInset(edge: .top) {
            modePicker
        }
        .sheet(isPresented: isShowingDetail) {
            PubDetailSheet(model: detail)
        }
        .task {
            // Last session's pubs first, marked with their age, so the screen
            // is never empty while the first fetch is under way.
            await pubs.loadCached()
            location.start()
            // The map normally reports its area as soon as it appears. If it
            // hasn't after a second, show London rather than an empty map.
            try? await Task.sleep(for: .seconds(1))
            pubs.loadIfIdle(in: BoundingBox(Self.fallbackRegion))
        }
        .onChange(of: userCoordinate, initial: true) { _, coordinate in
            pubs.userLocationChanged(to: coordinate)
        }
        .onChange(of: scenePhase) { previous, phase in
            handleScenePhase(from: previous, to: phase)
        }
        .task(id: refreshInterval) {
            await refreshPeriodically()
        }
    }

    // MARK: - Freshness

    /// Back from the background, everything on screen may be out of date: open
    /// states change with the clock. Location updates pause while away.
    private func handleScenePhase(from previous: ScenePhase, to phase: ScenePhase) {
        switch phase {
        case .active:
            location.start()
            if previous == .background {
                pubs.refresh()
                detail.refresh()
            }
        case .background:
            location.stop()
        default:
            break
        }
    }

    private var refreshInterval: Duration {
        Freshness.refreshInterval(for: pubs.pubs)
    }

    /// Refetch on a timer while the screen is up. Restarted (by `.task(id:)`)
    /// whenever the interval changes, e.g. when a pub nears closing.
    private func refreshPeriodically() async {
        let interval = refreshInterval
        while !Task.isCancelled {
            try? await Task.sleep(for: interval)
            guard !Task.isCancelled else {
                return
            }
            pubs.refresh()
        }
    }

    /// The sheet is open while a pub is selected; dismissing it deselects.
    private var isShowingDetail: Binding<Bool> {
        Binding(
            get: {
                detail.selected != nil
            },
            set: { isShowing in
                if !isShowing {
                    detail.deselect()
                }
            }
        )
    }

    /// The user's position in the client's terms (CoreLocation stays out of it).
    private var userCoordinate: Coordinate? {
        location.coordinate.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
    }

    // MARK: - Overlays

    private var modePicker: some View {
        Picker("Show pubs as", selection: $mode) {
            ForEach(Mode.allCases) { mode in
                Label(mode.rawValue, systemImage: mode.systemImage)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    @ViewBuilder
    private var statusBanner: some View {
        VStack(spacing: 8) {
            if location.authorization == .denied {
                Button {
                    if let settings = URL(string: UIApplication.openSettingsURLString) {
                        openURL(settings)
                    }
                } label: {
                    Label("Location is off. Turn it on in Settings to see pubs near you.", systemImage: "location.slash")
                        .font(.footnote)
                }
                .buttonStyle(.borderedProminent)
            }
            TimelineView(.everyMinute) { context in
                if let fetchedAt = pubs.fetchedAt,
                   pubs.isShowingCached || Freshness.isStale(fetchedAt: fetchedAt, now: context.date) {
                    FreshnessLabel(fetchedAt: fetchedAt)
                }
            }
            // The list shows its own notice; on the map it is a banner.
            if mode == .map, let notice = pubs.notice {
                noticeBanner(notice)
            } else if pubs.isLoading {
                ProgressView()
                    .padding(8)
                    .background(.thinMaterial, in: Circle())
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 16)
    }

    private func noticeBanner(_ notice: PubsNotice) -> some View {
        VStack(spacing: 8) {
            Label(notice.message, systemImage: notice.systemImage)
                .font(.footnote)
            NoticeActions(notice: notice, onGoToLondon: goToLondon, onRetry: pubs.refresh)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    /// Back to where the data is, on the map.
    private func goToLondon() {
        mode = .map
        withAnimation {
            position = .region(Self.fallbackRegion)
        }
    }

    /// Pub data comes from OpenStreetMap (ODbL), which requires this credit
    /// wherever it is shown, including on Apple's map.
    private var attribution: some View {
        Text("Pub data © OpenStreetMap contributors")
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.thinMaterial, in: Capsule())
            // Clear of Apple's own "Legal" label in the bottom corner.
            .padding(.bottom, 32)
    }
}

#Preview("Live data") {
    PubsMapScreen(source: PubDBClient())
}
