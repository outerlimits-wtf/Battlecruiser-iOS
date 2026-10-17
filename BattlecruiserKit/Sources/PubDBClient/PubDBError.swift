import Foundation
import PubDBModels

/// Everything that can go wrong talking to PubDB. Cancellation is not one of
/// these: a cancelled request throws `CancellationError`, which callers ignore.
public enum PubDBError: Error, Equatable, Sendable {
    /// No usable connection: offline, timed out, DNS, TLS.
    case transport(URLError)
    /// The server answered with its structured error body.
    case server(status: Int, APIErrorDetail)
    /// A non-2xx status without a readable error body.
    case http(status: Int)
    /// A response that is not JSON. Unknown paths come back as the web app's
    /// HTML with a 200, so a wrong URL looks like this rather than a 404.
    case unexpectedContent(status: Int, contentType: String?)
    /// JSON the models could not decode. Carries the decoder's description.
    case decoding(String)

    /// True when the device has no usable connection, so the UI can say "offline"
    /// and keep showing what it already has.
    public var isOffline: Bool {
        guard case .transport(let error) = self else { return false }
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed,
             .internationalRoamingOff, .timedOut, .cannotFindHost, .cannotConnectToHost,
             .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    /// A short line to show the user. The server's own message is written for
    /// people (docs/backend/03-api-reference.md), so it is used when there is one.
    public var userMessage: String {
        switch self {
        case .server(_, let detail):
            detail.message
        case .transport where isOffline:
            "You're offline. Showing what was loaded last."
        case .transport, .http, .unexpectedContent, .decoding:
            "Couldn't reach PubDB just now. Try again in a moment."
        }
    }
}
