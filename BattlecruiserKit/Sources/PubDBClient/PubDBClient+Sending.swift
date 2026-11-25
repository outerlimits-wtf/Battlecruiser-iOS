import Foundation
import PubDBModels

/// Sending a request and turning what comes back into a value or a `PubDBError`.
extension PubDBClient {
    func send<Response: Decodable>(_ endpoint: Endpoint) async throws -> Response {
        let requestedAt = now()
        let (data, http) = try await exchange(endpoint, at: requestedAt)

        let decoded: Response
        do {
            decoded = try JSONCoding.decoder.decode(Response.self, from: data)
        } catch {
            throw PubDBError.decoding(String(describing: error))
        }

        // Saved only once it is known to decode, so the cache never holds a
        // response the app cannot read. Stamped with the `at` it describes.
        if let cache, let key = endpoint.cacheKey, http.statusCode == 200 {
            await cache.store(data, for: key, fetchedAt: requestedAt)
        }
        return decoded
    }

    /// Sends the request and checks the response: a 2xx with JSON, a `304`
    /// (only possible when `headers` asked for one), or a thrown error.
    func exchange(
        _ endpoint: Endpoint,
        at requestedAt: Date,
        headers: [String: String] = [:]
    ) async throws -> (Data, HTTPURLResponse) {
        guard var request = endpoint.request(baseURL: baseURL, now: requestedAt) else {
            throw PubDBError.http(status: 0)
        }
        for (name, value) in headers {
            request.setValue(value, forHTTPHeaderField: name)
        }

        // Every request carries the token when signed in (reads too: `canRemove`
        // and `isFollowing` depend on it). On a 401, refresh once and retry once.
        let token = await tokens?.accessToken()
        var (data, http) = try await transmit(request, token: token)
        if http.statusCode == 401, token != nil, let fresh = await tokens?.refreshedAccessToken() {
            (data, http) = try await transmit(request, token: fresh)
        }
        let status = http.statusCode
        let contentType = http.value(forHTTPHeaderField: "Content-Type")
        // `application/json`, and `application/geo+json` from `/pins`.
        let isJSON = contentType?.lowercased().contains("json") ?? false
        let detail = isJSON ? (try? JSONCoding.decoder.decode(APIErrorBody.self, from: data))?.error : nil

        if status == 304 {
            return (data, http)
        }
        if status == 429 {
            throw PubDBError.rateLimited(retryAfter: Self.retryAfter(http), detail)
        }
        guard (200..<300).contains(status) else {
            if let detail {
                throw PubDBError.server(status: status, detail)
            }
            throw PubDBError.http(status: status)
        }
        guard isJSON else {
            throw PubDBError.unexpectedContent(status: status, contentType: contentType)
        }
        return (data, http)
    }

    /// Sends one request, with the token if there is one.
    private func transmit(_ request: URLRequest, token: String?) async throws -> (Data, HTTPURLResponse) {
        var request = request
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
        guard let http = response as? HTTPURLResponse else {
            throw PubDBError.http(status: 0)
        }
        return (data, http)
    }

    /// `Retry-After` in seconds, the only form the server sends.
    static func retryAfter(_ response: HTTPURLResponse) -> TimeInterval? {
        response.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
    }

    /// Decodes a saved response exactly as a fresh one is decoded. An entry that
    /// no longer decodes (say, after a model change) is removed, not shown.
    func cached<Value: Decodable & Sendable>(_ type: Value.Type, key: String) async -> Cached<Value>? {
        guard let cache, let entry = await cache.load(key) else {
            return nil
        }
        guard let value = try? JSONCoding.decoder.decode(Value.self, from: entry.data) else {
            await cache.remove(key)
            return nil
        }
        return Cached(value: value, fetchedAt: entry.fetchedAt)
    }
}
