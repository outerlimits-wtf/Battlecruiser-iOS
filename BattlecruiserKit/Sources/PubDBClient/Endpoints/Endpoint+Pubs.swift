import Foundation

/// `GET /pubs`, `GET /pubs/{id}` and `GET /pubs/{id}/similar`.
extension Endpoint {
    /// Only the latest list is kept: areas vary, and on launch the last one
    /// the user saw is the useful one.
    static let lastPubsCacheKey = "pubs/last"

    static func pubCacheKey(_ id: String) -> String {
        "pub/\(id)"
    }

    static func pubs(in area: BoundingBox, near location: Coordinate?, amenity: String, limit: Int) -> Endpoint {
        Endpoint(
            path: ["pubs"],
            query: [
                URLQueryItem(name: "bbox", value: area.queryValue),
                URLQueryItem(name: "amenity", value: amenity),
                URLQueryItem(name: "limit", value: String(limit)),
            ] + QueryItems.location(location),
            cacheKey: lastPubsCacheKey
        )
    }

    static func pub(id: String, near location: Coordinate?) -> Endpoint {
        Endpoint(path: ["pubs", id], query: QueryItems.location(location), cacheKey: pubCacheKey(id))
    }

    static func similar(to id: String, near location: Coordinate?) -> Endpoint {
        Endpoint(path: ["pubs", id, "similar"], query: QueryItems.location(location))
    }
}
