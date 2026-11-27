import PubDBClient
import PubDBModels

/// The notification calls. `PubDBClient` in the app.
public protocol NotificationSource: Sendable {
    func fetchNotifications() async throws -> NotificationInbox
    func markRead(upTo id: Int?) async throws -> UnreadCount
    func fetchNotificationSettings() async throws -> NotificationSettings
    func saveNotificationSettings(_ settings: NotificationSettings) async throws -> NotificationSettings
    func register(device token: String, environment: String) async throws
    func unregister(device token: String) async throws
}

extension PubDBClient: NotificationSource {
    public nonisolated func fetchNotifications() async throws -> NotificationInbox {
        try await notifications()
    }

    public nonisolated func markRead(upTo id: Int?) async throws -> UnreadCount {
        try await markNotificationsRead(upTo: id)
    }

    public nonisolated func fetchNotificationSettings() async throws -> NotificationSettings {
        try await notificationSettings()
    }

    public nonisolated func saveNotificationSettings(_ settings: NotificationSettings) async throws -> NotificationSettings {
        try await updateNotificationSettings(settings)
    }

    public nonisolated func register(device token: String, environment: String) async throws {
        try await registerDevice(token, environment: environment)
    }

    public nonisolated func unregister(device token: String) async throws {
        try await unregisterDevice(token)
    }
}
