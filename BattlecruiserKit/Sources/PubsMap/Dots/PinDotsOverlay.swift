import MapKit

/// One overlay covering the world, under which every pub is a dot. One overlay
/// rather than an annotation per pub: thousands of views can't move smoothly.
final class PinDotsOverlay: NSObject, MKOverlay {
    let coordinate = CLLocationCoordinate2D(latitude: 51.5, longitude: -0.12)
    let boundingMapRect = MKMapRect.world
}
