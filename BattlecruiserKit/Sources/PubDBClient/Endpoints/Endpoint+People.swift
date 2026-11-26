import Foundation

/// `/users/{username}`, following, and the person's own lists.
extension Endpoint {
    static func profile(_ username: String) -> Endpoint {
        Endpoint(path: ["users", username])
    }

    static func follow(_ username: String, _ on: Bool) -> Endpoint {
        Endpoint(method: on ? .put : .delete, path: ["users", username, "follow"], sendsClock: false)
    }

    static func savedPubs(_ list: SavedList, near location: Coordinate?) -> Endpoint {
        Endpoint(path: [list.rawValue], query: QueryItems.location(location))
    }

    static func mark(_ pubID: String, on list: SavedList, _ on: Bool) -> Endpoint {
        Endpoint(method: on ? .put : .delete, path: ["pubs", pubID, list.markPath], sendsClock: false)
    }
}
