import Foundation

/// `PUT`/`DELETE /users/{username}/follow`: the result, with the new count.
public struct FollowChange: Decodable, Hashable, Sendable {
    public let username: String
    public let following: Bool
    public let followers: Int
}
