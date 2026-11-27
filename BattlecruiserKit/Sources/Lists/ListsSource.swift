import PubDBClient
import PubDBModels

/// The signed-in person's lists. `PubDBClient` in the app.
public protocol ListsSource: Sendable {
    func fetchSaved(_ list: SavedList, near location: Coordinate?) async throws -> SavedPubs
}

extension PubDBClient: ListsSource {
    public nonisolated func fetchSaved(_ list: SavedList, near location: Coordinate?) async throws -> SavedPubs {
        try await savedPubs(list, near: location)
    }
}
