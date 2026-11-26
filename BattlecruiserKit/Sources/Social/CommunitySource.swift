import PubDBClient
import PubDBModels

/// What the Social tab reads. `PubDBClient` in the app.
public protocol CommunitySource: Sendable {
    func fetchFeed(following: Bool) async throws -> Feed
    func fetchLeaderboard() async throws -> Leaderboard
    func fetchBoard(_ key: String, near location: Coordinate?) async throws -> Board
}

extension PubDBClient: CommunitySource {
    public nonisolated func fetchFeed(following: Bool) async throws -> Feed {
        try await feed(following: following)
    }

    public nonisolated func fetchLeaderboard() async throws -> Leaderboard {
        try await leaderboard()
    }

    public nonisolated func fetchBoard(_ key: String, near location: Coordinate?) async throws -> Board {
        try await board(key, near: location)
    }
}
