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

/// The area to ask for pubs in: the visible map region.
public struct BoundingBox: Hashable, Sendable {
    public var west: Double
    public var south: Double
    public var east: Double
    public var north: Double

    public init(west: Double, south: Double, east: Double, north: Double) {
        self.west = west
        self.south = south
        self.east = east
        self.north = north
    }

    /// The box around a map region, given its centre and span in degrees, as
    /// MapKit describes a visible region.
    public init(center: Coordinate, latitudeDelta: Double, longitudeDelta: Double) {
        self.init(
            west: center.longitude - longitudeDelta / 2,
            south: center.latitude - latitudeDelta / 2,
            east: center.longitude + longitudeDelta / 2,
            north: center.latitude + latitudeDelta / 2
        )
    }

    public var center: Coordinate {
        Coordinate(latitude: (south + north) / 2, longitude: (west + east) / 2)
    }

    /// Whether `other` lies entirely inside this box.
    public func contains(_ other: BoundingBox) -> Bool {
        other.west >= west && other.east <= east && other.south >= south && other.north <= north
    }

    /// Whether the two boxes share any area at all.
    public func intersects(_ other: BoundingBox) -> Bool {
        other.west < east && other.east > west && other.south < north && other.north > south
    }

    /// `west,south,east,north`: longitude first. This is what production
    /// accepts; the v1 spec's "south,west,north,east" is wrong
    /// (docs/backend/03-api-reference.md, "Spec vs production").
    var queryValue: String {
        [west, south, east, north].map(QueryFormat.degrees).joined(separator: ",")
    }
}

enum QueryFormat {
    /// Five decimal places is about a metre: plenty for a map, and it keeps URLs
    /// short and stable. `String(format:)` without a locale always uses a ".".
    static func degrees(_ value: Double) -> String {
        String(format: "%.5f", value)
    }
}
