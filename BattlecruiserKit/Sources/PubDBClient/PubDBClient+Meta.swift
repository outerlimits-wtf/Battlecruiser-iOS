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
}
