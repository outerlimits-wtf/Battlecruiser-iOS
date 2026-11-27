import PubDBClient
import PubDBModels

/// The signed-in person's lists, as far as marking pubs goes. `PubDBClient` in the app.
public protocol MarksSource: Sendable {
    func fetchSavedIDs(_ list: SavedList) async throws -> Set<String>
    func setMark(_ pubID: String, on list: SavedList, _ on: Bool) async throws -> PubMark
}

extension PubDBClient: MarksSource {
    public nonisolated func fetchSavedIDs(_ list: SavedList) async throws -> Set<String> {
        Set(try await savedPubs(list).pubs.map(\.id))
    }
}
