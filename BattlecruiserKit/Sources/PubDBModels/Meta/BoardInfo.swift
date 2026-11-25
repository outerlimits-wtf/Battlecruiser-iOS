import Foundation

/// A pub board the server offers (best rated, cheapest pint…), with its labels.
/// Its entries come from `GET /boards/{key}`.
public struct BoardInfo: Decodable, Hashable, Sendable, Identifiable {
    public let key: String
    public let title: String
    public let blurb: String
    public let emoji: String
    /// How it is ranked, in a sentence or two.
    public let note: String?

    public var id: String { key }
}
