import Foundation

/// `GET /feed`, `/leaderboard` and `/boards/{key}`.
extension Endpoint {
    static func feed(following: Bool, limit: Int) -> Endpoint {
        Endpoint(
            path: ["feed"],
            query: [URLQueryItem(name: "limit", value: String(limit))]
                + (following ? [URLQueryItem(name: "following", value: "true")] : [])
        )
    }

    static let leaderboard = Endpoint(path: ["leaderboard"])

    static func board(_ key: String, near location: Coordinate?, limit: Int) -> Endpoint {
        Endpoint(
            path: ["boards", key],
            query: [URLQueryItem(name: "limit", value: String(limit))] + QueryItems.location(location)
        )
    }
}
