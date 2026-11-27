import Foundation

/// The body of every non-2xx response:
/// `{ "error": { "code": "not_found", "message": "…", "field": "at" } }`.
public struct APIErrorBody: Decodable, Hashable, Sendable {
    public let error: APIErrorDetail
}
