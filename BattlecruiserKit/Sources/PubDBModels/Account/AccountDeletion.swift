import Foundation

/// `DELETE /me`: what went with the account.
public struct AccountDeletion: Decodable, Hashable, Sendable {
    public struct Removed: Decodable, Hashable, Sendable {
        public let reviews: Int
        public let photos: Int
    }

    public struct Anonymised: Decodable, Hashable, Sendable {
        public let contributions: Int
    }

    public let deleted: Bool
    public let removed: Removed
    public let anonymised: Anonymised
}
