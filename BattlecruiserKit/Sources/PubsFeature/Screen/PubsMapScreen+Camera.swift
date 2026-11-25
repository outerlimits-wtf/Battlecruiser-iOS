import MapKit
import SwiftUI
import PubDBClient

extension PubsMapScreen {
    /// Where the map opens without the user's location: central London, where
    /// all the data is.
    static let fallbackRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.5098, longitude: -0.1257),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )

    /// How much of the map shows around the user on opening: street level,
    /// with the nearby pubs in view.
    static let openingSpanMetres: CLLocationDistance = 1500

    /// Bring the map to the user's first position. MapKit's follow-the-user
    /// camera does not reliably move when the first fix arrives after the map
    /// is on screen (the first-launch case: permission prompt, then a fix), so
    /// this moves it explicitly. Once per launch, and never if the user has
    /// already moved the map themselves.
    func centerOnUserIfNeeded(at coordinate: Coordinate?) {
        guard let coordinate, !hasCenteredOnUser, !position.positionedByUser else {
            return
        }
        hasCenteredOnUser = true
        position = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
            latitudinalMeters: Self.openingSpanMetres,
            longitudinalMeters: Self.openingSpanMetres
        ))
    }

    /// Back to where the data is, on the map.
    func goToLondon() {
        mode = .map
        withAnimation(reduceMotion ? nil : .default) {
            position = .region(Self.fallbackRegion)
        }
    }
}
