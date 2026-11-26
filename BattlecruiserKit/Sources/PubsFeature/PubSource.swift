import PubDBClient
import PubDBModels

/// Where `PubsModel` gets pubs from. `PubDBClient` in the app; a scripted fake
/// in tests, so the model's timing and error handling can be tested offline.
public protocol PubSource {
    /// `area` is nil when the query doesn't use one (a search, or "everywhere").
    func fetchPubs(matching query: PubQuery, in area: BoundingBox?, near location: Coordinate?) async throws -> PubList
    /// The last list fetched, saved on disk; nil if there is none.
    func cachedPubs() async -> Cached<PubList>?
}

extension PubDBClient: PubSource {
    // This module defaults to the main actor; the client's work belongs off it.
    public nonisolated func fetchPubs(matching query: PubQuery, in area: BoundingBox?, near location: Coordinate?) async throws -> PubList {
        try await pubs(matching: query, in: area, near: location)
    }
}
