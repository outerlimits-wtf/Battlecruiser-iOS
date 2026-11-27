import Foundation

/// `GET /boards/{key}`: pubs ranked by the server. Draw them in the order sent.
public struct Board: Decodable, Hashable, Sendable {
    public struct Entry: Decodable, Hashable, Sendable, Identifiable {
        public let rank: Int
        public let pub: PubSummary
        /// The figure it is ranked on, ready to show ("£3.99", "8.7").
        public let value: String
        /// "1 report · 2 months ago".
        public let detail: String?

        public var id: String { pub.id }
    }

    public struct Excluded: Decodable, Hashable, Sendable {
        public let count: Int
        public let reason: String
    }

    public struct Empty: Decodable, Hashable, Sendable {
        public let title: String
        public let body: String
    }

    public let board: BoardInfo
    public let entries: [Entry]
    public let excluded: Excluded?
    public let empty: Empty

    private enum CodingKeys: String, CodingKey {
        case board, entries, excluded, empty
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        board = try container.decode(BoardInfo.self, forKey: .board)
        entries = try LossyArray.decode(Entry.self, from: container, forKey: .entries)
        excluded = try container.decodeIfPresent(Excluded.self, forKey: .excluded)
        empty = try container.decode(Empty.self, forKey: .empty)
    }
}
