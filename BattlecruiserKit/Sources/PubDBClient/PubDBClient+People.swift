import Foundation
import PubDBModels

/// Profiles, following, and the hit list and Been here.
extension PubDBClient {
    /// Anyone's page; signed in, it also says whether you follow them.
    public func profile(_ username: String) async throws -> Profile {
        try await send(.profile(username))
    }

    public func setFollowing(_ username: String, _ on: Bool) async throws -> FollowChange {
        try await send(.follow(username, on))
    }

    /// The signed-in person's list. Signed out is `401`.
    public func savedPubs(_ list: SavedList, near location: Coordinate? = nil) async throws -> SavedPubs {
        try await send(.savedPubs(list, near: location))
    }

    /// Put a pub on a list, or take it off.
    public func setMark(_ pubID: String, on list: SavedList, _ on: Bool) async throws -> PubMark {
        try await send(.mark(pubID, on: list, on))
    }
}
