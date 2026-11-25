import Foundation

/// The HTTP methods the v1 API uses. Reads are `GET`; every write needs a
/// signed-in account (spec, "Accounts and sessions").
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
