import Foundation
import PubDBModels

/// Pub lists and pub details, live and from the cache.
extension PubDBClient {
    /// Pubs inside `area`, nearest its centre first. Pass the user's `location`
    /// to get a distance on each pub.
    public func pubs(
        in area: BoundingBox,
        near location: Coordinate? = nil,
        amenity: String = PubDBClient.defaultAmenity,
        limit: Int = PubDBClient.defaultLimit
    ) async throws -> PubList {
        try await send(.pubs(in: area, near: location, amenity: amenity, limit: limit))
    }

    /// One pub in full.
    public func pub(id: String, near location: Coordinate? = nil) async throws -> PubDetail {
        try await send(.pub(id: id, near: location))
    }

    /// Up to six of the nearest other places to a pub.
    public func similar(to id: String, near location: Coordinate? = nil) async throws -> PubList {
        try await send(.similar(to: id, near: location))
    }

    /// The last pub list fetched, if one was saved.
    public func cachedPubs() async -> Cached<PubList>? {
        await cached(PubList.self, key: Endpoint.lastPubsCacheKey)
    }

    /// The last detail fetched for this pub, if one was saved.
    public func cachedPub(id: String) async -> Cached<PubDetail>? {
        await cached(PubDetail.self, key: Endpoint.pubCacheKey(id))
    }
}
