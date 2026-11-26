import Foundation

/// What a place is: `pub`, `gastropub`, `wine_bar`… Shown with its own label and
/// symbol, not its group's.
public struct VenueKind: Decodable, Hashable, Sendable, Identifiable {
    public let key: String
    /// The `amenity` group it is listed under: "pub" or "bar".
    public let group: String
    public let label: String
    public let symbol: Symbol
    /// One line on what the name means, shown behind an ⓘ. Nil for most kinds.
    public let note: String?

    public var id: String { key }
}
