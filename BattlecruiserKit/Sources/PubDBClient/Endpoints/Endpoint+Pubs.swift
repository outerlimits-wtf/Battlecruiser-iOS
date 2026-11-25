import Foundation

/// `GET /pubs`, `GET /pubs/{id}` and `GET /pubs/{id}/similar`.
extension Endpoint {
    /// Only the latest list is kept: areas vary, and on launch the last one
    /// the user saw is the useful one.
    static let lastPubsCacheKey = "pubs/last"

    static func pubCacheKey(_ id: String) -> String {
        "pub/\(id)"
    }

    /// The list. `area` is left out when the query searches or looks everywhere.
    static func pubs(matching query: PubQuery, in area: BoundingBox?, near location: Coordinate?, limit: Int) -> Endpoint {
        let areaItems = query.usesArea ? area.map { [URLQueryItem(name: "bbox", value: $0.queryValue)] } ?? [] : []
        return Endpoint(
            path: ["pubs"],
            query: areaItems + query.items + [URLQueryItem(name: "limit", value: String(limit))] + QueryItems.location(location),
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
