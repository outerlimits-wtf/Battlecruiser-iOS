import SwiftUI
import PubDBClient
import PubsMap

extension PubsMapScreen {
    /// Central London, where most of the data is: the list's fallback area,
    /// and where "Go to London" goes.
    static let london = Coordinate(latitude: 51.5098, longitude: -0.1257)
    static let fallbackArea = BoundingBox(center: london, latitudeDelta: 0.03, longitudeDelta: 0.03)

    /// How much of the map shows around the user on opening: street level,
    /// with the nearby pubs in view.
    static let openingSpanMetres = 1000.0

    /// Bring the map to the user's first position, once per launch, and never
    /// if the user has already moved the map themselves.
    func centerOnUserIfNeeded(at coordinate: Coordinate?) {
        guard let coordinate, !hasCenteredOnUser, settledCount <= 1 else {
            return
        }
        hasCenteredOnUser = true
        cameraRequest = .show(latitude: coordinate.latitude, longitude: coordinate.longitude, metres: Self.openingSpanMetres)
    }

    /// Back to where the data is, on the map.
    func goToLondon() {
        mode = .map
        cameraRequest = .show(latitude: Self.london.latitude, longitude: Self.london.longitude, metres: 3000)
    }
}
