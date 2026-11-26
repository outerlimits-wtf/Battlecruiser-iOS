import PubDBClient
import PubDBModels

/// What a profile page reads and changes. `PubDBClient` in the app.
public protocol ProfileSource: Sendable {
    func fetchProfile(_ username: String) async throws -> Profile
    func setFollowing(_ username: String, _ on: Bool) async throws -> FollowChange
}

extension PubDBClient: ProfileSource {
    public nonisolated func fetchProfile(_ username: String) async throws -> Profile {
        try await profile(username)
    }
}
