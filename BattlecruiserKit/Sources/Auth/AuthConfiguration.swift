import Foundation

/// How the app signs in with WorkOS AuthKit as a public client (spec,
/// "Native clients"): no API key on the device, PKCE instead.
public struct AuthConfiguration: Sendable, Equatable {
    public var clientID: String
    /// Registered in the WorkOS dashboard.
    public var redirectURI: URL
    public var apiBase: URL

    public static let redirect = URL(string: "wtf.outerlimits.battlecruiser:/auth/callback")!
    public static let workOS = URL(string: "https://api.workos.com")!
    /// The Info.plist key holding the WorkOS client id.
    public static let clientIDInfoKey = "WorkOSClientID"

    public init(clientID: String, redirectURI: URL = AuthConfiguration.redirect, apiBase: URL = AuthConfiguration.workOS) {
        self.clientID = clientID
        self.redirectURI = redirectURI
        self.apiBase = apiBase
    }

    /// The scheme the sign-in sheet listens for.
    public var callbackScheme: String {
        redirectURI.scheme ?? ""
    }

    /// From the app's Info.plist, or nil when no client id is set (then the
    /// app offers no sign-in, as when the server has none).
    public static func fromBundle(_ bundle: Bundle = .main) -> AuthConfiguration? {
        guard let id = bundle.object(forInfoDictionaryKey: clientIDInfoKey) as? String,
              !id.trimmingCharacters(in: .whitespaces).isEmpty
        else { return nil }
        return AuthConfiguration(clientID: id)
    }
}
