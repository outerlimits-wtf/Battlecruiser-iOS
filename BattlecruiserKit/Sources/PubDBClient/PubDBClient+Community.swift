import Foundation
import PubDBModels

/// What people have been adding, who adds the most, and the boards.
extension PubDBClient {
    /// The latest facts and reviews; `following` (signed in) for the people you follow.
    public func feed(following: Bool = false, limit: Int = 50) async throws -> Feed {
        try await send(.feed(following: following, limit: limit))
    }

    public func leaderboard() async throws -> Leaderboard {
        try await send(.leaderboard)
    }

    /// One of the boards `/meta` lists.
    public func board(_ key: String, near location: Coordinate? = nil, limit: Int = 25) async throws -> Board {
        try await send(.board(key, near: location, limit: limit))
    }
}
