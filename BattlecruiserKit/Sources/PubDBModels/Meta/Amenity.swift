import Foundation

/// One of the groups the `amenity` filter takes (`pub` or `bar`).
public struct Amenity: Decodable, Hashable, Sendable, Identifiable {
    public let key: String
    public let kind: String
    public let label: String
    public let symbol: Symbol

    public var id: String { key }
}
