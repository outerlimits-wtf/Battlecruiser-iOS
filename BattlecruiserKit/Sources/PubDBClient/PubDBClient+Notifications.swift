import Foundation
import PubDBModels

/// The inbox, what pushes, and registering this phone for pushes.
extension PubDBClient {
    public func notifications(limit: Int = 50) async throws -> NotificationInbox {
        try await send(.notifications(limit: limit))
    }

    /// Mark this one and everything older read; nil marks all. Returns the new badge.
    public func markNotificationsRead(upTo id: Int?) async throws -> UnreadCount {
        try await send(.markRead(upTo: id))
    }

    public func notificationSettings() async throws -> NotificationSettings {
        let envelope: NotificationSettingsEnvelope = try await send(.notificationSettings)
        return envelope.settings
    }

    public func updateNotificationSettings(_ settings: NotificationSettings) async throws -> NotificationSettings {
        let envelope: NotificationSettingsEnvelope = try await send(.updateNotificationSettings(settings))
        return envelope.settings
    }

    /// Register this phone's APNs token (lowercase hex). `sandbox` for a build
    /// run from Xcode, `production` for TestFlight and the App Store.
    public func registerDevice(_ token: String, environment: String) async throws {
        let _: Ignored = try await send(.device(token, register: true, environment: environment))
    }

    /// Unregister on sign-out, before the token is dropped.
    public func unregisterDevice(_ token: String) async throws {
        let _: Ignored = try await send(.device(token, register: false, environment: ""))
    }
}
