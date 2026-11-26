import Foundation
import Observation
import PubDBClient
import PubDBModels

/// Which pubs are on the hit list and which are ticked off, for the panel's
/// Save and Been here buttons. Toggles show at once and are put back if the
/// server refuses, as on the web.
@Observable
public final class MarksModel {
    public private(set) var watching: Set<String> = []
    public private(set) var visited: Set<String> = []

    @ObservationIgnored private let source: any MarksSource

    public init(source: any MarksSource) {
        self.source = source
    }

    /// Fetch both lists' ids; call once signed in.
    public func load() async {
        async let watchingIDs = try? source.fetchSavedIDs(.watchlist)
        async let visitedIDs = try? source.fetchSavedIDs(.visited)
        if let ids = await watchingIDs { watching = ids }
        if let ids = await visitedIDs { visited = ids }
    }

    /// Forget everything, on signing out.
    public func clear() {
        watching = []
        visited = []
    }

    public func contains(_ pubID: String, on list: SavedList) -> Bool {
        set(for: list).contains(pubID)
    }

    /// Note a change the server made itself (posting a review marks it visited).
    public func noteVisited(_ pubID: String) {
        visited.insert(pubID)
    }

    public func toggle(_ pubID: String, on list: SavedList) async {
        let wasOn = contains(pubID, on: list)
        set(pubID, on: list, to: !wasOn)
        do {
            _ = try await source.setMark(pubID, on: list, !wasOn)
        } catch {
            set(pubID, on: list, to: wasOn)
        }
    }

    private func set(for list: SavedList) -> Set<String> {
        list == .watchlist ? watching : visited
    }

    private func set(_ pubID: String, on list: SavedList, to isOn: Bool) {
        var ids = set(for: list)
        if isOn { ids.insert(pubID) } else { ids.remove(pubID) }
        if list == .watchlist { watching = ids } else { visited = ids }
    }
}
