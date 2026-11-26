import Foundation

/// `PUT`/`DELETE /pubs/{id}/reviews/{reviewId}/like`: the heart as it now is.
public struct LikeChange: Decodable, Hashable, Sendable {
    public let reviewId: Int
    public let liked: Bool
    public let likes: Int
}
