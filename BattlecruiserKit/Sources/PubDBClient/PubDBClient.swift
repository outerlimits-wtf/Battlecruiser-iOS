import Foundation
import ResponseCache

/// Talks to the PubDB v1 API (`../pubdb/spec/pubdb-api-v1.md`).
///
/// Callers cancel by cancelling their `Task`; a cancelled request throws
/// `CancellationError`. Everything else that goes wrong is a `PubDBError`.
///
/// The requests for each area of the API are in `PubDBClient+<Area>.swift`;
/// sending and response checks are in `PubDBClient+Sending.swift`.
///
/// Given a `ResponseCache`, it saves the raw bytes of responses worth keeping
/// (the last pub list, each pub detail), so they can be shown at once on the
/// next launch or without signal.
public struct PubDBClient: Sendable {
    /// Production. Reads are public, so development builds use it too (decision D14).
    public static let productionBaseURL = URL(string: "https://pubdb.outerlimits.wtf/api/v1")!

    /// The Info.plist key that can point the app at another server, e.g. a
    /// local `bun dev`. Production when absent.
    public static let baseURLInfoKey = "PubDBBaseURL"

    /// Enough to fill the visible map without flooding it (decision R5).
    public static let defaultLimit = 200

    let baseURL: URL
    let transport: any HTTPTransport
    let now: @Sendable () -> Date
    let cache: ResponseCache?
    /// Shared by copies of this client, so every caller benefits from a tag.
    let etags = ETagStore()
    /// The signed-in person's tokens; nil sends every request signed out.
    let tokens: (any TokenProvider)?

    /// - Parameters:
    ///   - baseURL: The API root, ending `/api/v1`.
    ///   - transport: How requests are sent; `URLSession.shared` unless testing.
    ///   - now: The device clock, sent as `at`. Injected so tests are repeatable.
    ///   - cache: Where to save responses. None by default, so tests and previews
    ///     never touch the app's real cache; the app uses `live()`.
    public init(
        baseURL: URL = PubDBClient.productionBaseURL,
        transport: any HTTPTransport = URLSession.shared,
        now: @escaping @Sendable () -> Date = { Date() },
        cache: ResponseCache? = nil,
        tokens: (any TokenProvider)? = nil
    ) {
        self.baseURL = baseURL
        self.transport = transport
        self.now = now
        self.cache = cache
        self.tokens = tokens
    }

    /// The app's client: the configured server, saving responses to the app's cache.
    public static func live(bundle: Bundle = .main, tokens: (any TokenProvider)? = nil) -> PubDBClient {
        PubDBClient(baseURL: configuredBaseURL(in: bundle), cache: .standard(), tokens: tokens)
    }

    /// The server named under `PubDBBaseURL` in the bundle's Info.plist, else production.
    public static func configuredBaseURL(in bundle: Bundle) -> URL {
        guard let value = bundle.object(forInfoDictionaryKey: baseURLInfoKey) as? String,
              let url = URL(string: value), url.scheme != nil
        else {
            return productionBaseURL
        }
        return url
    }
}
