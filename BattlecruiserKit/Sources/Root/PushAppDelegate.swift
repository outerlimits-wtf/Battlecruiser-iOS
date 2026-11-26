import UIKit
import UserNotifications
import AppEnvironment

/// The app delegate, only for what SwiftUI can't do: take the APNs token and
/// hear about tapped pushes. Both go to `PushInbox`, which the root reads.
/// Used from the app target with `@UIApplicationDelegateAdaptor`.
public final class PushAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushInbox.shared.received(token: deviceToken)
    }

    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        // No push entitlement in this build, or no network: the inbox still works.
    }

    /// Show pushes that arrive while the app is open, as banners.
    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .badge, .sound]
    }

    public nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let payload = response.notification.request.content.userInfo
        await MainActor.run { PushInbox.shared.tapped(payload: payload) }
    }
}
