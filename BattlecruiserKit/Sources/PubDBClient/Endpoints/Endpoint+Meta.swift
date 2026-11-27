import Foundation

/// `GET /meta`.
extension Endpoint {
    static let metaCacheKey = "meta"

    /// Not time-dependent, so no `at`.
    static let meta = Endpoint(path: ["meta"], sendsClock: false, cacheKey: metaCacheKey)
}
