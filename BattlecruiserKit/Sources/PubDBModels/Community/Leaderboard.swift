import Foundation

/// `GET /leaderboard`: who has added the most, and the totals under the table.
public struct Leaderboard: Decodable, Hashable, Sendable {
    public struct Contributor: Decodable, Hashable, Sendable, Identifiable {
        public let rank: Int
        /// "@goatloaf".
        public let name: String
        public let attribution: Attribution
        public let avatarUrl: String?
        public let contributions: Int
        public let reviews: Int
        public let total: Int
        public let pubs: Int
        public let agoLabel: String

        public var id: String { name }
        public var avatarURL: URL? { avatarUrl.flatMap(URL.init(string:)) }
    }

    public struct Imported: Decodable, Hashable, Sendable {
        public let label: String
        public let total: Int
    }

    public struct Anonymous: Decodable, Hashable, Sendable {
        public let total: Int
    }

    public struct Totals: Decodable, Hashable, Sendable {
        public let people: Int
        public let contributions: Int
        public let reviews: Int
    }

    public let contributors: [Contributor]
    public let imported: Imported?
    public let anonymous: Anonymous?
    public let totals: Totals
}
