import PubDBClient
import PubDBModels

/// Where `PubDetailModel` gets a pub's full detail from. `PubDBClient` in the
/// app; a scripted fake in tests.
public protocol PubDetailSource {
    func fetchPub(id: String, near location: Coordinate?) async throws -> PubDetail
    /// The last detail fetched for this pub, saved on disk; nil if there is none.
    func cachedPub(id: String) async -> Cached<PubDetail>?
}

extension PubDBClient: PubDetailSource {
    // This module defaults to the main actor; the client's work belongs off it.
    public nonisolated func fetchPub(id: String, near location: Coordinate?) async throws -> PubDetail {
        try await pub(id: id, near: location)
    }
}
