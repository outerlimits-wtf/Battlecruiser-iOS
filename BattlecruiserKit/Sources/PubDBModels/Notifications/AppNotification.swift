import Foundation

/// One notification: someone liked your review, followed you, or someone you
/// follow posted. `text` is the whole sentence; draw it as sent.
public struct AppNotification: Decodable, Hashable, Sendable, Identifiable {
    public struct Actor: Decodable, Hashable, Sendable {
        public let username: String
        public let label: String
        public let avatarUrl: String?

        public var avatarURL: URL? { avatarUrl.flatMap(URL.init(string:)) }
    }

    public struct Pub: Decodable, Hashable, Sendable {
        public let id: String
        public let name: String
    }

    public let id: Int
    /// "review_liked", "followed", "following_review", "following_photo", or a
    /// newer one: unknown types still show, with a plain icon.
    public let type: String
    public let text: String
    public let agoLabel: String
    public let read: Bool
    public let actor: Actor?
    /// Null only for "followed".
    public let pub: Pub?
    public let reviewId: Int?
    public let photoId: Int?

    /// Where a tap goes: their profile for a follow, else the pub.
    public var opensProfile: Bool { type == "followed" }
}
