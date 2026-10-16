import Foundation

/// The body of every non-2xx response:
/// `{ "error": { "code": "not_found", "message": "…", "field": "at" } }`.
public struct APIErrorBody: Decodable, Hashable, Sendable {
    public let error: APIErrorDetail
}

public struct APIErrorDetail: Decodable, Hashable, Sendable {
    /// What to switch on: "invalid_request", "not_found", "rate_limited", …
    public let code: String
    /// Written for people; safe to show. Never match on it, it gets reworded.
    public let message: String
    /// The input at fault, when there was one.
    public let field: String?
}
