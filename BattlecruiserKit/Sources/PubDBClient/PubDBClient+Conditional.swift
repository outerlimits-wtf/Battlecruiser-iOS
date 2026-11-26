import Foundation

/// Conditional GETs (`If-None-Match` → `304`), for `/pins` today and any other
/// endpoint that starts sending an `ETag`.
extension PubDBClient {
    func sendConditional<Response: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> Conditional<Response> {
        let key = endpoint.etagKey
        let known = await etags.tag(for: key)
        let headers = known.map { ["If-None-Match": $0] } ?? [:]

        let (data, http) = try await exchange(endpoint, at: now(), headers: headers)
        if http.statusCode == 304 {
            return .unchanged
        }

        let decoded: Response
        do {
            decoded = try JSONCoding.decoder.decode(Response.self, from: data)
        } catch {
            throw PubDBError.decoding(String(describing: error))
        }
        // Remembered only once the body is known to decode.
        await etags.remember(http.value(forHTTPHeaderField: "ETag"), for: key)
        return .changed(decoded)
    }
}
