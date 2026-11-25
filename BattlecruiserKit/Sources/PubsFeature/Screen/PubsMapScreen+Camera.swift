import SwiftUI
import PubDBClient
import PubsMap

/// Where the map goes when the screen moves it.
enum MapPlaces {
    /// Central London, where most of the data is: the list's fallback area,
    /// and where "Go to London" goes.
    static let london = Coordinate(latitude: 51.5098, longitude: -0.1257)
    static let fallbackArea = BoundingBox(center: london, latitudeDelta: 0.03, longitudeDelta: 0.03)

    /// How much of the map shows around the user on opening: street level,
    /// with the nearby pubs in view (the web's zoom 16).
    static let openingSpanMetres = 1000.0
}

extension PubsMapScreen {
    /// Bring the map to the user's first position, once per launch, and never
    /// if the user has already moved the map themselves.
    func centerOnUserIfNeeded(at coordinate: Coordinate?) {
        guard let coordinate, !hasCenteredOnUser, !userHasMovedMap else {
            return
        }
        hasCenteredOnUser = true
        cameraRequest = .show(latitude: coordinate.latitude, longitude: coordinate.longitude, metres: MapPlaces.openingSpanMetres)
    }

    /// Back to where the data is, on the map.
    func goToLondon() {
        detent = .peek
        cameraRequest = .show(latitude: MapPlaces.london.latitude, longitude: MapPlaces.london.longitude, metres: 3000)
    }
}
