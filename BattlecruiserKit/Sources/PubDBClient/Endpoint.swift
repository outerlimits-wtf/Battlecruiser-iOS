import Foundation

/// The v1 requests the app makes, as path components plus query items. Every
/// request carries `at` (the device clock) so the server reasons about "open
/// now" and "tonight" from the user's moment, not its own.
struct Endpoint: Equatable, Sendable {
    /// Path segments after the base URL, not yet percent-encoded.
    var path: [String]
    var query: [URLQueryItem]

    static func pubs(in area: BoundingBox, near location: Coordinate?, amenity: String, limit: Int) -> Endpoint {
        Endpoint(
            path: ["pubs"],
            query: [
                URLQueryItem(name: "bbox", value: area.queryValue),
                URLQueryItem(name: "amenity", value: amenity),
                URLQueryItem(name: "limit", value: String(limit)),
            ] + locationItems(location)
        )
    }

    static func pub(id: String, near location: Coordinate?) -> Endpoint {
        Endpoint(path: ["pubs", id], query: locationItems(location))
    }

    static func similar(to id: String, near location: Coordinate?) -> Endpoint {
        Endpoint(path: ["pubs", id, "similar"], query: locationItems(location))
    }

    private static func locationItems(_ location: Coordinate?) -> [URLQueryItem] {
        guard let location else { return [] }
        return [
            URLQueryItem(name: "lat", value: QueryFormat.degrees(location.latitude)),
            URLQueryItem(name: "lon", value: QueryFormat.degrees(location.longitude)),
        ]
    }

    /// The full request. `now` becomes the `at` parameter.
    func request(baseURL: URL, now: Date) -> URLRequest? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return nil }
        let base = components.percentEncodedPath.hasSuffix("/")
            ? String(components.percentEncodedPath.dropLast())
            : components.percentEncodedPath
        components.percentEncodedPath = base + path.map { "/" + Self.encodePathSegment($0) }.joined()
        components.queryItems = query + [URLQueryItem(name: "at", value: now.ISO8601Format())]
        // URLComponents leaves "+" alone in queries, and servers read it as a space.
        components.percentEncodedQuery = components.percentEncodedQuery?
            .replacingOccurrences(of: "+", with: "%2B")

        guard let url = components.url else { return nil }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    /// Pub ids contain a slash ("node/123"); inside a path it must be "%2F" or
    /// the server sees two segments.
    static func encodePathSegment(_ segment: String) -> String {
        let allowed = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
        return segment.addingPercentEncoding(withAllowedCharacters: allowed) ?? segment
    }
}
