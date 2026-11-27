import Foundation

/// `GET /meta`.
extension Endpoint {
    static let metaCacheKey = "meta"

    /// Not time-dependent, so no `at`.
    static let meta = Endpoint(path: ["meta"], sendsClock: false, cacheKey: metaCacheKey)
}

/// `GET /brands`, for the operator picker.
extension Endpoint {
    static let brandsCacheKey = "brands"

    /// No `at`, no paging.
    static let brands = Endpoint(path: ["brands"], sendsClock: false, cacheKey: brandsCacheKey)
}
