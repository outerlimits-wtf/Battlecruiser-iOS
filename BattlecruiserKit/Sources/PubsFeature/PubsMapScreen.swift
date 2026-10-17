import MapKit
import SwiftUI
import UIKit
import PubDBClient
import UserLocation

/// The app's main screen: the map of pubs around the user.
///
/// Owns the screen's state (pubs and location) and connects them: the user's
/// position goes to the API for distances, and the map's area drives fetching.
public struct PubsMapScreen: View {
    /// Where the map opens without the user's location: central London, where
    /// all the data is.
    static let fallbackRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.5098, longitude: -0.1257),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )

    @State private var pubs: PubsModel
    @State private var location = LocationModel()
    /// Follows the user once a fix arrives; until then, and if refused, London.
    @State private var position: MapCameraPosition = .userLocation(fallback: .region(PubsMapScreen.fallbackRegion))
    @Environment(\.openURL) private var openURL

    /// - Parameter source: Where pubs come from; the app passes its `PubDBClient`.
    public init(source: any PubSource) {
        _pubs = State(initialValue: PubsModel(source: source))
    }

    public var body: some View {
        PubMap(position: $position, pubs: pubs.pubs) { area in
            pubs.areaChanged(to: area)
        }
        .overlay(alignment: .top) {
            statusBanner
        }
        .overlay(alignment: .bottom) {
            attribution
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

    /// The user's position in the client's terms (CoreLocation stays out of it).
    private var userCoordinate: Coordinate? {
        location.coordinate.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
    }

    // MARK: - Overlays

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
