import Foundation

/// `POST` or `DELETE /me/avatar`: the picture now, or nil.
public struct AvatarChange: Decodable, Hashable, Sendable {
    public let avatarUrl: String?
}
