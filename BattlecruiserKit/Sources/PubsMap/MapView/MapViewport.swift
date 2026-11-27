import MapKit
import PubDBClient

/// Where the map has settled: the box it shows, and how zoomed in it is.
public struct MapViewport: Equatable, Sendable {
    public let area: BoundingBox
    /// Metres one screen point covers. Small means zoomed in.
    public let metresPerPoint: Double
    /// Whether the person moved the map to get here, rather than the app.
    public let movedByUser: Bool

    init(area: BoundingBox, metresPerPoint: Double, movedByUser: Bool = false) {
        self.area = area
        self.metresPerPoint = metresPerPoint
        self.movedByUser = movedByUser
    }

    init(_ mapView: MKMapView, movedByUser: Bool) {
        self.movedByUser = movedByUser
        let region = mapView.region
        area = BoundingBox(
            center: Coordinate(latitude: region.center.latitude, longitude: region.center.longitude),
            latitudeDelta: region.span.latitudeDelta,
            longitudeDelta: region.span.longitudeDelta
        )
        let width = max(mapView.bounds.width, 1)
        let metresPerMapPoint = MKMetersPerMapPointAtLatitude(region.center.latitude)
        metresPerPoint = mapView.visibleMapRect.width * metresPerMapPoint / width
    }
}
