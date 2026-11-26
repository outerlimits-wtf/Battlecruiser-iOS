import Foundation
import PubDBModels

/// Who is signed in, and changing their account.
extension PubDBClient {
    /// Always answers, signed in or not. Call on launch and on resume.
    public func me() async throws -> Me {
        try await send(.me)
    }

    /// Change the handle. The server tidies it (lowercase, spaces to `_`) and
    /// answers with `/me` as it now is; a taken one is `409 duplicate_value`.
    public func rename(to username: String) async throws -> Me {
        try await send(.rename(to: username))
    }

    /// Delete the account for good. Confirm with the person first.
    public func deleteAccount() async throws -> AccountDeletion {
        try await send(.deleteAccount)
    }

    /// A new picture: JPEG, PNG, WebP or GIF, up to 5 MB.
    public func uploadAvatar(_ image: MultipartForm.File) async throws -> AvatarChange {
        try await send(.uploadAvatar(image))
    }

    public func removeAvatar() async throws -> AvatarChange {
        try await send(.removeAvatar)
    }
}
