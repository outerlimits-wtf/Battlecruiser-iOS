import Foundation

/// Settings that differ per build and aren't secret.
enum AppConfig {
    /// The WorkOS client id (`client_…`), from the WorkOS dashboard, where the
    /// redirect `wtf.outerlimits.battlecruiser:/auth/callback` is registered.
    /// A public client id, not a secret: no API key goes on the device.
    /// Empty: the app offers no sign-in.
    static let workOSClientID = ""
}
