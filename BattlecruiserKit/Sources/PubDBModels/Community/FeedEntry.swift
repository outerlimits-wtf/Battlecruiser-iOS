import Foundation

/// One thing someone added: a fact (`contribution`) or a review, newest first.
public struct FeedEntry: Decodable, Hashable, Sendable, Identifiable {
    public struct Pub: Decodable, Hashable, Sendable {
        public let id: String
        public let name: String
        public let amenityLabel: String
        public let symbol: Symbol
    }

    /// "contribution" or "review".
    public let kind: String
    public let entryID: Int
    public let pub: Pub
    /// Contributions: what changed, ready to show.
    public let fieldLabel: String?
    public let displayValue: String?
    /// Reviews: the score and what they said.
    public let rating: Int?
    public let body: String?
    public let agoLabel: String
    public let attribution: Attribution
    public let avatarUrl: String?

    public var id: String { "\(kind)/\(entryID)" }
    public var avatarURL: URL? { avatarUrl.flatMap(URL.init(string:)) }
    public var isReview: Bool { kind == "review" }

    private enum CodingKeys: String, CodingKey {
        case kind, entryID = "id", pub, fieldLabel, displayValue, rating, body, agoLabel, attribution, avatarUrl
    }
}
