import Foundation

/// The `{ key, label, symbol }` shape shared by amenities and summary features.
public struct LabelledSymbol: Decodable, Hashable, Sendable, Identifiable {
    public let key: String
    public let label: String
    public let symbol: Symbol

    public var id: String { key }
}
