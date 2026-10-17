import MapKit
import SwiftUI
import UIKit
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
                    isLoading: pubs.isLoading,
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
            location.start()
            // The map normally reports its area as soon as it appears. If it
            // hasn't after a second, show London rather than an empty map.
            try? await Task.sleep(for: .seconds(1))
            pubs.loadIfIdle(in: BoundingBox(Self.fallbackRegion))
        }
        .onChange(of: userCoordinate, initial: true) { _, coordinate in
            pubs.userLocationChanged(to: coordinate)
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
            if let error = pubs.lastError {
                Text(error.userMessage)
                    .font(.footnote)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.thinMaterial, in: Capsule())
            } else if pubs.isLoading {
                ProgressView()
                    .padding(8)
                    .background(.thinMaterial, in: Circle())
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 16)
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
