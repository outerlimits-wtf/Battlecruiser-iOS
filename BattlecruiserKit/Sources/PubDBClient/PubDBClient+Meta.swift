import Foundation
import PubDBModels

/// The server's lists, labels and limits.
extension PubDBClient {
    public func meta() async throws -> Meta {
        try await send(.meta)
    }

    /// The last `/meta` fetched, so launch never waits on the network for it.
    public func cachedMeta() async -> Cached<Meta>? {
        await cached(Meta.self, key: Endpoint.metaCacheKey)
    }

    /// Every operator (`brand`) in the data with its pub count, most first.
    public func brands() async throws -> [Brand] {
        let list: BrandList = try await send(.brands)
        return list.brands
    }
}
