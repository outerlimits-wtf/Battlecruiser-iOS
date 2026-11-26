import Foundation

/// `PUT`/`DELETE /pubs/{id}/watch` and `/visited`: whether it is now on the list.
public struct PubMark: Decodable, Hashable, Sendable {
    public let pubId: String
    public let watching: Bool?
    public let visited: Bool?
}
