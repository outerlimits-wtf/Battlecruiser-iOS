import MapKit

/// Something the screen asks the map to do with its camera. Handed over once,
/// then cleared, so the map never fights the user's own panning.
public enum MapCameraRequest: Equatable, Sendable {
    /// Show this centre with this many metres across.
    case show(latitude: Double, longitude: Double, metres: Double)
    /// Follow the user, as the locate button does.
    case followUser

    func apply(to mapView: MKMapView, animated: Bool) {
        switch self {
        case .show(let latitude, let longitude, let metres):
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                latitudinalMeters: metres,
                longitudinalMeters: metres
            )
            mapView.setRegion(region, animated: animated)
        case .followUser:
            mapView.setUserTrackingMode(.follow, animated: animated)
        }
    }
}
