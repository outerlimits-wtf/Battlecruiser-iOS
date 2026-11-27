import Foundation

/// Where the client gets the signed-in person's access token (decision P7:
/// WorkOS bearer tokens). The `Auth` module provides the real one; the client
/// knows nothing about how tokens are got or kept.
public protocol TokenProvider: Sendable {
    /// The current access token, or nil when signed out.
    func accessToken() async -> String?
    /// A new access token after the server refused the last one, or nil if
    /// it couldn't be refreshed (the person is then signed out).
    func refreshedAccessToken() async -> String?
}
