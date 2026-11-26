import Foundation

/// `POST /pubs/{id}/photos`: whether it's up or waiting for an admin, in the
/// server's words.
public struct PhotoUploadResult: Decodable, Hashable, Sendable {
    /// "approved" or "pending".
    public let status: String
    public let message: String?
}
