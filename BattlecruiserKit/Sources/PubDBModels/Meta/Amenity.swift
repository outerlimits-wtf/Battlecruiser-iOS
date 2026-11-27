import Foundation

/// What a place is. In `/meta` it is one of the two groups the `amenity`
/// filter takes (`pub` or `bar`); on a pub, `key` is the group and `kind` the
/// venue kind (`gastropub`, `wine_bar`…), whose note lives in `/meta`.
public struct Amenity: Decodable, Hashable, Sendable, Identifiable {
    public let key: String
    /// The venue kind key. Optional only so a payload from before kinds existed
    /// still decodes.
    public let kind: String?
    public let label: String
    public let symbol: Symbol

    public var id: String { key }
}
