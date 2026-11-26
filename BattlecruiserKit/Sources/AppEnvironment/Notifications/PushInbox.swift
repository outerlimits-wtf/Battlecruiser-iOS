import Foundation
import Observation

/// Where the app delegate drops what iOS hands it about pushes: this phone's
/// token, and a push the person tapped. The root reads both.
@Observable
public final class PushInbox {
    public static let shared = PushInbox()

    /// The APNs token as lowercase hex, once iOS has given one.
    public var deviceToken: String?
    /// A tapped push, waiting to be opened.
    public var tapped: PushRoute?

    public init() {}

    /// From `didRegisterForRemoteNotificationsWithDeviceToken`.
    public func received(token: Data) {
        deviceToken = token.map { String(format: "%02x", $0) }.joined()
    }

    /// From a tapped notification's `pubdb` payload.
    public func tapped(payload: [AnyHashable: Any]) {
        guard let pubdb = payload["pubdb"] as? [String: Any] else { return }
        tapped = PushRoute(
            type: pubdb["type"] as? String ?? "",
            username: pubdb["username"] as? String,
            pubID: pubdb["pubId"] as? String
        )
    }
}
