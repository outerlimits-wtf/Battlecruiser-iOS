import Foundation

/// `POST /notifications/read`: the badge after marking read.
public struct UnreadCount: Decodable, Hashable, Sendable {
    public let unread: Int
}
