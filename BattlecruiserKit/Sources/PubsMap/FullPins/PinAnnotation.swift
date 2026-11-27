import MapKit
import PubDBModels

/// One full pin on the map. Kept while its pub stays in view and unchanged, so
/// MapKit never rebuilds a view it already has.
final class PinAnnotation: NSObject, MKAnnotation {
    let pin: Pin

    init(_ pin: Pin) {
        self.pin = pin
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
    }

    var title: String? { pin.name }
    var subtitle: String? { pin.label }
}
