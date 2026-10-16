import Foundation

/// Anything the server draws an icon for: an amenity, a feature, a status, a
/// "tonight" marker. `emoji` is always present and is what the MVP draws
/// (decision D17); `key` is the stable identifier and `url` optional artwork.
public struct Symbol: Decodable, Hashable, Sendable {
    public let key: String
    /// "emoji" or "icon" today. Kept as a string so a new type never fails decoding.
    public let type: String
    public let emoji: String
    public let url: String?
}

/// The `{ key, label, symbol }` shape shared by amenities and summary features.
public struct LabelledSymbol: Decodable, Hashable, Sendable, Identifiable {
    public let key: String
    public let label: String
    public let symbol: Symbol

    public var id: String { key }
}

/// Who a fact came from. Only `label` is shown; `sourceKey` is for auditing.
public struct Attribution: Decodable, Hashable, Sendable {
    /// "user", "source" or "anonymous".
    public let kind: String
    public let label: String
    public let sourceKey: String?
}
