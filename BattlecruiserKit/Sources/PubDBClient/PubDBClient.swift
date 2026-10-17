import Foundation
import PubDBModels

/// Reads pubs from the PubDB v1 API (docs/backend/03-api-reference.md).
///
/// Read-only for the MVP: no sign-in, no writes. Callers cancel by cancelling
/// their `Task`; a cancelled request throws `CancellationError`. Everything else
/// that goes wrong is a `PubDBError`.
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

    /// - Parameters:
    ///   - baseURL: The API root, ending `/api/v1`.
    ///   - transport: How requests are sent; `URLSession.shared` unless testing.
    ///   - now: The device clock, sent as `at`. Injected so tests are repeatable.
    public init(
        baseURL: URL = PubDBClient.productionBaseURL,
        transport: any HTTPTransport = URLSession.shared,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.baseURL = baseURL
        self.transport = transport
        self.now = now
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

    // MARK: - Sending

    func fetch<Response: Decodable>(_ endpoint: Endpoint) async throws -> Response {
        guard let request = endpoint.request(baseURL: baseURL, now: now()) else {
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

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw PubDBError.decoding(String(describing: error))
        }
    }
}
