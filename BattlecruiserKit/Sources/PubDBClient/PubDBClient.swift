import Foundation
import PubDBModels
import ResponseCache

/// A value read back from the cache, and when the server sent it.
public struct Cached<Value: Sendable>: Sendable {
    public let value: Value
    public let fetchedAt: Date

    public init(value: Value, fetchedAt: Date) {
        self.value = value
        self.fetchedAt = fetchedAt
    }
}

/// Reads pubs from the PubDB v1 API (docs/backend/03-api-reference.md).
///
/// Read-only for the MVP: no sign-in, no writes. Callers cancel by cancelling
/// their `Task`; a cancelled request throws `CancellationError`. Everything else
/// that goes wrong is a `PubDBError`.
///
/// Given a `ResponseCache`, it saves the raw bytes of the last pub list and of
/// each pub detail it fetches, so they can be shown at once on the next launch
/// or without signal (`cachedPubs()`, `cachedPub(id:)`).
public struct PubDBClient: Sendable {
    /// Production. Reads are public, so development builds use it too (decision D14).
    public static let productionBaseURL = URL(string: "https://pubdb.outerlimits.wtf/api/v1")!

    /// Pubs are asked for by default; bars only when the user wants them (decision D4).
    public static let defaultAmenity = "pub"
    /// Enough to fill the visible map without flooding it (decision R5).
    public static let defaultLimit = 200

    private let baseURL: URL
    private let transport: any HTTPTransport
    private let now: @Sendable () -> Date
    private let cache: ResponseCache?

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
        cache: ResponseCache? = nil
    ) {
        self.baseURL = baseURL
        self.transport = transport
        self.now = now
        self.cache = cache
    }

    /// The app's client: production, saving responses to the app's cache.
    public static func live() -> PubDBClient {
        PubDBClient(cache: .standard())
    }

    /// Pubs inside `area`, nearest its centre first. Pass the user's `location`
    /// to get a distance on each pub.
    public func pubs(
        in area: BoundingBox,
        near location: Coordinate? = nil,
        amenity: String = PubDBClient.defaultAmenity,
        limit: Int = PubDBClient.defaultLimit
    ) async throws -> PubList {
        try await fetch(.pubs(in: area, near: location, amenity: amenity, limit: limit))
    }

    /// One pub in full.
    public func pub(id: String, near location: Coordinate? = nil) async throws -> PubDetail {
        try await fetch(.pub(id: id, near: location))
    }

    /// Up to six of the nearest other places to a pub.
    public func similar(to id: String, near location: Coordinate? = nil) async throws -> PubList {
        try await fetch(.similar(to: id, near: location))
    }

    // MARK: - Cached responses

    /// The last pub list fetched, if one was saved.
    public func cachedPubs() async -> Cached<PubList>? {
        await cached(PubList.self, key: Endpoint.lastPubsCacheKey)
    }

    /// The last detail fetched for this pub, if one was saved.
    public func cachedPub(id: String) async -> Cached<PubDetail>? {
        await cached(PubDetail.self, key: Endpoint.pubCacheKey(id))
    }

    /// Decodes a saved response exactly as a fresh one is decoded. An entry that
    /// no longer decodes (say, after a model change) is removed, not shown.
    private func cached<Value: Decodable & Sendable>(_ type: Value.Type, key: String) async -> Cached<Value>? {
        guard let cache, let entry = await cache.load(key) else {
            return nil
        }
        guard let value = try? JSONDecoder().decode(Value.self, from: entry.data) else {
            await cache.remove(key)
            return nil
        }
        return Cached(value: value, fetchedAt: entry.fetchedAt)
    }

    // MARK: - Sending

    func fetch<Response: Decodable>(_ endpoint: Endpoint) async throws -> Response {
        let requestedAt = now()
        guard let request = endpoint.request(baseURL: baseURL, now: requestedAt) else {
            throw PubDBError.http(status: 0)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.send(request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as URLError {
            throw PubDBError.transport(error)
        }
        try Task.checkCancellation()

        let http = response as? HTTPURLResponse
        let status = http?.statusCode ?? 0
        let contentType = http?.value(forHTTPHeaderField: "Content-Type")
        let isJSON = contentType?.lowercased().contains("application/json") ?? false

        guard (200..<300).contains(status) else {
            if isJSON, let body = try? JSONDecoder().decode(APIErrorBody.self, from: data) {
                throw PubDBError.server(status: status, body.error)
            }
            throw PubDBError.http(status: status)
        }
        guard isJSON else {
            throw PubDBError.unexpectedContent(status: status, contentType: contentType)
        }

        let decoded: Response
        do {
            decoded = try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw PubDBError.decoding(String(describing: error))
        }

        // Saved only once it is known to decode, so the cache never holds a
        // response the app cannot read. Stamped with the `at` it describes.
        if let cache, let key = endpoint.cacheKey {
            await cache.store(data, for: key, fetchedAt: requestedAt)
        }
        return decoded
    }
}
