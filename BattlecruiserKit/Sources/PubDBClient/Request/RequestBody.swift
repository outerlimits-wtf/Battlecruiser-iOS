import Foundation

/// What a write sends. JSON for contributions, reviews, reports and the
/// account; multipart for photo and avatar uploads.
enum RequestBody: Sendable {
    /// Encoded when the request is built, so a factory never has to throw.
    case json(any Encodable & Sendable)
    case multipart(MultipartForm)

    /// The bytes and their `Content-Type`, or nil if the value would not encode.
    func encoded() -> (data: Data, contentType: String)? {
        switch self {
        case .json(let value):
            guard let data = try? JSONCoding.encoder.encode(value) else { return nil }
            return (data, "application/json")
        case .multipart(let form):
            return (form.encoded(), form.contentType)
        }
    }
}
