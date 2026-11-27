import PubDBClient
import PubDBModels

/// The account calls `SessionModel` makes. `PubDBClient` in the app.
public protocol SessionSource: Sendable {
    func fetchMe() async throws -> Me
    func rename(to username: String) async throws -> Me
    func deleteAccount() async throws -> AccountDeletion
    func uploadAvatar(_ image: MultipartForm.File) async throws -> AvatarChange
    func removeAvatar() async throws -> AvatarChange
}

extension PubDBClient: SessionSource {
    public nonisolated func fetchMe() async throws -> Me {
        try await me()
    }
}
