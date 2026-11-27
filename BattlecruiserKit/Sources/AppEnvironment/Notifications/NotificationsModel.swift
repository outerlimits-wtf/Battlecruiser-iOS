import Foundation
import Observation
import PubDBClient
import PubDBModels

/// The signed-in person's notifications: the inbox, the badge, what pushes,
/// and this phone's registration for pushes.
@Observable
public final class NotificationsModel {
    public private(set) var inbox = Loadable<NotificationInbox>()
    /// The badge: unread notifications.
    public private(set) var unread = 0
    public private(set) var settings: NotificationSettings?

    @ObservationIgnored private let source: any NotificationSource
    @ObservationIgnored private var registeredToken: String?

    public init(source: any NotificationSource) {
        self.source = source
    }

    /// The inbox and the badge.
    public func load() async {
        inbox.start()
        do {
            let fresh = try await source.fetchNotifications()
            inbox.succeed(fresh, at: Date())
            unread = fresh.unread
        } catch {
            inbox.fail(error)
        }
    }

    /// The inbox was shown: everything in it is read (not every push received).
    public func markAllRead() async {
        guard unread > 0, let newest = inbox.value?.notifications.first?.id else { return }
        if let answer = try? await source.markRead(upTo: newest) {
            unread = answer.unread
        }
    }

    public func loadSettings() async {
        settings = try? await source.fetchNotificationSettings()
    }

    /// Change what pushes; shows at once, put back if refused.
    public func update(_ change: NotificationSettings) async {
        let before = settings
        settings = change
        do {
            settings = try await source.saveNotificationSettings(change)
        } catch {
            settings = before
        }
    }

    /// Register this phone (every launch while signed in: tokens change).
    public func register(deviceToken: String, environment: String) async {
        if (try? await source.register(device: deviceToken, environment: environment)) != nil {
            registeredToken = deviceToken
        }
    }

    /// On sign-out, before the access token goes, or the phone keeps getting
    /// the old account's pushes.
    public func unregisterDevice() async {
        guard let token = registeredToken else { return }
        try? await source.unregister(device: token)
        registeredToken = nil
    }

    /// Signed out: nothing to show.
    public func clear() {
        inbox = Loadable()
        unread = 0
        settings = nil
    }
}
