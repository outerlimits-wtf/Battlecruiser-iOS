import Foundation

/// A point on the map. Kept free of CoreLocation so this module stays Foundation-only;
/// features convert from `CLLocationCoordinate2D` at their edge.
public struct Coordinate: Hashable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
