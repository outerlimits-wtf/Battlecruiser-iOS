import MapKit

/// What the map is drawn on. Apple Maps today (decision P2); another base, such
/// as CARTO's vector tiles, would be a new case here and nothing else.
public enum MapBase: Sendable {
    /// Apple's standard map, muted so the pubs stand out.
    case appleMuted

    func configure(_ mapView: MKMapView) {
        switch self {
        case .appleMuted:
            let configuration = MKStandardMapConfiguration(emphasisStyle: .muted)
            configuration.pointOfInterestFilter = .excludingAll
            mapView.preferredConfiguration = configuration
        }
    }
}
