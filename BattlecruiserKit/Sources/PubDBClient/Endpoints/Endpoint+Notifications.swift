import Foundation
import PubDBModels

/// `/notifications`, `/me/notification-settings` and `/me/devices/{token}`.
extension Endpoint {
    private struct ReadBody: Encodable, Sendable {
        let upTo: Int?
    }

    private struct DeviceBody: Encodable, Sendable {
        let platform: String
        let environment: String
    }

    static func notifications(limit: Int) -> Endpoint {
        Endpoint(path: ["notifications"], query: [URLQueryItem(name: "limit", value: String(limit))])
    }

    static func markRead(upTo id: Int?) -> Endpoint {
        Endpoint(method: .post, path: ["notifications", "read"], body: .json(ReadBody(upTo: id)), sendsClock: false)
    }

    static let notificationSettings = Endpoint(path: ["me", "notification-settings"], sendsClock: false)

    static func updateNotificationSettings(_ settings: NotificationSettings) -> Endpoint {
        Endpoint(method: .patch, path: ["me", "notification-settings"], body: .json(settings), sendsClock: false)
    }

    static func device(_ token: String, register: Bool, environment: String) -> Endpoint {
        Endpoint(
            method: register ? .put : .delete,
            path: ["me", "devices", token],
            body: register ? .json(DeviceBody(platform: "ios", environment: environment)) : nil,
            sendsClock: false
        )
    }
}
