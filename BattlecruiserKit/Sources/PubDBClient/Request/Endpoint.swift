import Foundation

/// One v1 request: method, path, query, and an optional body. Time-dependent
/// requests carry `at` (the device clock) so the server reasons about "open
/// now" and "tonight" from the user's moment, not its own.
///
/// The factories for each area of the API live in `Endpoints/`.
struct Endpoint: Sendable {
    var method: HTTPMethod = .get
    /// Path segments after the base URL, not yet percent-encoded.
    var path: [String]
    var query: [URLQueryItem] = []
    var body: RequestBody? = nil
    /// Whether to append `at`. True for anything that says what is open.
    var sendsClock = true
    /// Where a successful response is saved, if it is worth saving.
    var cacheKey: String? = nil

    /// The full request, or nil if it cannot be built. `now` becomes `at`.
    func request(baseURL: URL, now: Date) -> URLRequest? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return nil }
        let base = components.percentEncodedPath.hasSuffix("/")
            ? String(components.percentEncodedPath.dropLast())
            : components.percentEncodedPath
        components.percentEncodedPath = base + path.map { "/" + Self.encodePathSegment($0) }.joined()
        let items = query + (sendsClock ? [URLQueryItem(name: "at", value: now.ISO8601Format())] : [])
        if !items.isEmpty {
            components.queryItems = items
            // URLComponents leaves "+" alone in queries, and servers read it as a space.
            components.percentEncodedQuery = components.percentEncodedQuery?
                .replacingOccurrences(of: "+", with: "%2B")
        }

        guard let url = components.url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            guard let encoded = body.encoded() else { return nil }
            request.httpBody = encoded.data
            request.setValue(encoded.contentType, forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    /// Pub ids contain a slash ("node/123"); inside a path it must be "%2F" or
    /// the server sees two segments.
    static func encodePathSegment(_ segment: String) -> String {
        let allowed = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
        return segment.addingPercentEncoding(withAllowedCharacters: allowed) ?? segment
    }
}
