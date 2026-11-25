import PubDBClient
import PubDBModels

/// Where `MetaStore` gets `/meta` from. `PubDBClient` in the app; a fake in tests.
public protocol MetaSource: Sendable {
    func fetchMeta() async throws -> Meta
    func cachedMeta() async -> Cached<Meta>?
}

extension PubDBClient: MetaSource {
    public nonisolated func fetchMeta() async throws -> Meta {
        try await meta()
    }
}
