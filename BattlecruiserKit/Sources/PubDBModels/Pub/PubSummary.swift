import Foundation

/// One pub as it appears in a list or on the map: everything needed to draw a
/// pin or a row. Every display string arrives ready-made from the server; show
/// the labels as sent rather than formatting the raw numbers (decision D12).
public struct PubSummary: Decodable, Hashable, Sendable, Identifiable {
    /// The OpenStreetMap id, e.g. "node/123". Contains a slash.
    public let id: String
    public let name: String
    /// The neighbourhood, for telling same-named pubs apart; nil when unknown.
    public let area: String?
    public let amenity: Amenity
    public let lat: Double
    public let lon: Double
    public let address: String?
    public let postcode: String?
    public let brand: String?
    /// Present only when the request carried `lat` and `lon`.
    public let distance: Distance?
    public let status: PubStatus
    public let open: OpenInfo
    /// When people are turned out tonight, else when the bell goes; nil if nobody has said.
    public let tonight: Tonight?
    public let guinness: Guinness?
    /// Average review rating out of 10; nil with no reviews.
    public let rating: Double?
    public let reviewCount: Int
    public let photo: Photo?
    /// Only the features answered "yes", already ordered.
    public internal(set) var features: [LabelledSymbol]
    public let listed: Bool
    /// A line from the pub's reviews to show on its card; nil when none is chosen.
    public let quote: Quote?
}
