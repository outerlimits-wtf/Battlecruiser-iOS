import Foundation
import Testing
import PubDBClient
import PubDBModels
@testable import AppEnvironment

@MainActor
struct NotificationsModelTests {
    private final class Source: NotificationSource, @unchecked Sendable {
        var readUpTo: Int??
        var registered: [String] = []
        var unregistered: [String] = []

        func fetchNotifications() async throws -> NotificationInbox {
            let json = #"{ "notifications": [ { "id": 31, "type": "followed", "text": "@x followed you", "agoLabel": "now", "read": false } ], "unread": 1 }"#
            return try JSONDecoder().decode(NotificationInbox.self, from: Data(json.utf8))
        }
        func markRead(upTo id: Int?) async throws -> UnreadCount {
            readUpTo = id
            return try JSONDecoder().decode(UnreadCount.self, from: Data(#"{"unread":0}"#.utf8))
        }
        func fetchNotificationSettings() async throws -> NotificationSettings { NotificationSettings() }
        func saveNotificationSettings(_ settings: NotificationSettings) async throws -> NotificationSettings { throw URLError(.notConnectedToInternet) }
        func register(device token: String, environment: String) async throws { registered.append(token) }
        func unregister(device token: String) async throws { unregistered.append(token) }
    }

    @Test func showingTheInboxMarksItReadUpToTheNewest() async {
        let source = Source()
        let model = NotificationsModel(source: source)

        await model.load()
        #expect(model.unread == 1)
        await model.markAllRead()

        #expect(source.readUpTo == .some(31))
        #expect(model.unread == 0)
    }

    @Test func signingOutUnregistersTheTokenThatWasRegistered() async {
        let source = Source()
        let model = NotificationsModel(source: source)

        await model.register(deviceToken: "abc", environment: "sandbox")
        await model.unregisterDevice()
        await model.unregisterDevice()

        #expect(source.unregistered == ["abc"])
    }

    @Test func aRefusedSettingIsPutBack() async {
        let model = NotificationsModel(source: Source())
        await model.loadSettings()

        await model.update(NotificationSettings(likes: false))

        #expect(model.settings?.likes == true)
    }
}
