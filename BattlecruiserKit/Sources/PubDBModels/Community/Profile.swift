import Foundation

/// `GET /users/{username}`: someone's page.
public struct Profile: Decodable, Hashable, Sendable {
    public struct User: Decodable, Hashable, Sendable {
        public let username: String
        public let label: String
        public let avatarUrl: String?

        public var avatarURL: URL? { avatarUrl.flatMap(URL.init(string:)) }
    }

    public struct Stats: Decodable, Hashable, Sendable {
        public let visited: Int
        public let reviews: Int
        public let contributions: Int
        public let followers: Int
        public let following: Int
    }

    public struct ReviewItem: Decodable, Hashable, Sendable, Identifiable {
        public let id: Int
        public let pubId: String
        public let pubName: String
        public let rating: Int
        public let body: String?
        public let agoLabel: String
    }

    public let user: User
    public let stats: Stats
    public let isFollowing: Bool
    public let isSelf: Bool
    public let coverage: Coverage?
    public let reviews: [ReviewItem]
    public let visited: [PubSummary]

    private enum CodingKeys: String, CodingKey {
        case user, stats, isFollowing, isSelf, coverage, reviews, visited
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        user = try container.decode(User.self, forKey: .user)
        stats = try container.decode(Stats.self, forKey: .stats)
        isFollowing = try container.decodeIfPresent(Bool.self, forKey: .isFollowing) ?? false
        isSelf = try container.decodeIfPresent(Bool.self, forKey: .isSelf) ?? false
        coverage = try? container.decodeIfPresent(Coverage.self, forKey: .coverage)
        reviews = try LossyArray.decode(ReviewItem.self, from: container, forKey: .reviews)
        visited = try LossyArray.decode(PubSummary.self, from: container, forKey: .visited)
    }
}
