import UIKit
import UserNotifications

/// Asking to send pushes, once signed in, then registering with APNs.
enum PushPermission {
    /// `sandbox` for builds run from Xcode, `production` for TestFlight and the
    /// App Store; it must match the build's `aps-environment` entitlement.
    static var environment: String {
        #if DEBUG
        "sandbox"
        #else
        "production"
        #endif
    }

    static func requestAndRegister() async {
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        if granted {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    static func setBadge(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }
}
