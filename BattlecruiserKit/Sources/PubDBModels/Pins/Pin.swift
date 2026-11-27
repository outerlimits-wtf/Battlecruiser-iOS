import Foundation

/// One pub on the map: where it is and how loud to draw it. Everything else
/// comes from `/pubs` or `/pubs/{id}` once it is tapped.
public struct Pin: Decodable, Hashable, Sendable, Identifiable {
    public let id: String
    public let latitude: Double
    public let longitude: Double
    public let name: String
    public let area: String?
    /// The amenity group: "pub" or "bar".
    public let amenity: String
    /// "open", "closing", "unknown", "closed", "paused", "gone". Kept as a
    /// string so a new state never fails decoding; the map treats unknown
    /// values as "unknown".
    public let state: String
    /// 5 (open) down to 0 (gone). The order to draw in, quietest first.
    public let rank: Int
    /// 🪦 gone, 🚧 paused, else the venue kind's emoji.
    public let emoji: String
    /// "Open till 23:00", "Closed now"; nil when the hours are unknown.
    public let label: String?

    public init(
        id: String, latitude: Double, longitude: Double, name: String, area: String?,
        amenity: String, state: String, rank: Int, emoji: String, label: String?
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
        self.area = area
        self.amenity = amenity
        self.state = state
        self.rank = rank
        self.emoji = emoji
        self.label = label
    }

    private enum CodingKeys: String, CodingKey {
        case geometry, properties
    }

    private struct Geometry: Decodable {
        /// GeoJSON order: longitude first.
        let coordinates: [Double]
    }

    private struct Properties: Decodable {
        let id: String
        let name: String
        let area: String?
        let amenity: String
        let pin: String
        let rank: Int
        let emoji: String
        let label: String?
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let geometry = try container.decode(Geometry.self, forKey: .geometry)
        guard geometry.coordinates.count >= 2 else {
            throw DecodingError.dataCorruptedError(
                forKey: .geometry, in: container, debugDescription: "A point needs a longitude and a latitude"
            )
        }
        let properties = try container.decode(Properties.self, forKey: .properties)
        self.init(
            id: properties.id,
            latitude: geometry.coordinates[1],
            longitude: geometry.coordinates[0],
            name: properties.name,
            area: properties.area,
            amenity: properties.amenity,
            state: properties.pin,
            rank: properties.rank,
            emoji: properties.emoji,
            label: properties.label
        )
    }
}
