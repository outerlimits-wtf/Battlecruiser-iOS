import Foundation
import Observation
import PubDBClient
import PubDBModels

/// Deciding when to fetch, and fetching.
extension PubsModel {

    // MARK: - Loading

    /// Whether `area` needs a fetch. An area inside the one already asked for
    /// is covered, unless it is less than half as wide: the server returns the
    /// pubs nearest the centre, so zooming well in can reveal pubs the wider
    /// fetch left out. After a failure, any change retries.
    func shouldFetch(_ area: BoundingBox) -> Bool {
        guard let requested = requestedArea, lastError == nil else {
            return true
        }
        let zoomedWellIn = (area.east - area.west) < (requested.east - requested.west) / 2
        return !requested.contains(area) || zoomedWellIn
    }

    func load(_ area: BoundingBox?, debounced: Bool) {
        loadTask?.cancel()
        if let area { requestedArea = area }
        let location = userLocation
        let query = query
        let fetchArea = query.usesArea ? area : nil
        loadTask = Task { [debounce, sleep] in
            do {
                if debounced {
                    try await sleep(debounce)
                }
                isLoading = true
                let list = try await source.fetchPubs(matching: query, in: fetchArea, near: location)
                // A newer request may have started while this one was in flight.
                try Task.checkCancellation()
                pubs = PubOrdering.forDisplay(list.pubs, keepingServerOrder: query.latestClose)
                fetchedAt = now()
                isShowingCached = false
                lastError = nil
                isLoading = false
            } catch {
                if let shown = PubDBError.wrapping(error) {
                    lastError = shown
                    isLoading = false
                } else if !Task.isCancelled {
                    // Superseded: the newer load owns `isLoading`. If nothing
                    // superseded it, stop showing a spinner.
                    isLoading = false
                }
            }
        }
    }
}
