import Foundation

/// `GET /pins`.
extension Endpoint {
    /// Every pub matching the filters. No `bbox`: the map gets everything once,
    /// and asks again only when the filters change (spec, "Building a map").
    static func pins(matching query: PubQuery) -> Endpoint {
        Endpoint(path: ["pins"], query: query.items)
    }
}
