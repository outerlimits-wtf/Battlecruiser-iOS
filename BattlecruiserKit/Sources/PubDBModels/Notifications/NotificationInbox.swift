import Foundation

/// `GET /notifications`: newest first, and the badge count.
public struct NotificationInbox: Decodable, Hashable, Sendable {
    public let notifications: [AppNotification]
    public let unread: Int

    private enum CodingKeys: String, CodingKey {
        case notifications, unread
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        notifications = try LossyArray.decode(AppNotification.self, from: container, forKey: .notifications)
        unread = try container.decodeIfPresent(Int.self, forKey: .unread) ?? 0
    }
}
