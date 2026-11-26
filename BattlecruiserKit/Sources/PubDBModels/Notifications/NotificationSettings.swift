import Foundation

/// Which kinds push to the phone. The inbox shows everything regardless.
public struct NotificationSettings: Codable, Hashable, Sendable {
    public var likes: Bool
    public var follows: Bool
    /// Reviews and photos from people you follow.
    public var following: Bool

    public init(likes: Bool = true, follows: Bool = true, following: Bool = true) {
        self.likes = likes
        self.follows = follows
        self.following = following
    }
}

/// `{ "settings": { … } }`, as the server wraps them.
public struct NotificationSettingsEnvelope: Decodable, Hashable, Sendable {
    public let settings: NotificationSettings
}
