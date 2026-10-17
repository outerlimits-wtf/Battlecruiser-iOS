import Foundation
import Observation
import PubDBClient
import PubDBModels

/// The pubs in the area the map is showing, kept up to date as it moves.
///
/// The map reports each area it settles on with `areaChanged(to:)`. The model
/// waits briefly (so a pan is one fetch, not twenty), cancels anything older,
/// skips areas it already covers, and publishes the result in display order.
/// A failed fetch keeps the pubs already on screen.
@Observable
public final class PubsModel {
    /// In display order: open, unknown, closed, each nearest first.
    public private(set) var pubs: [PubSummary] = []
    public private(set) var isLoading = false
    /// The last fetch's failure, cleared by the next success. `pubs` is kept.
    public private(set) var lastError: PubDBError? = nil
    /// When `pubs` was fetched. Open states are true only for that moment.
    public private(set) var fetchedAt: Date? = nil
    /// True while `pubs` came from the disk cache rather than this session's fetch.
    public private(set) var isShowingCached = false

    /// How many of `pubs` can serve you right now.
    public var openCount: Int {
        pubs.filter { PubOrdering.rank($0) == 0 }.count
    }

    @ObservationIgnored private let source: any PubSource
    @ObservationIgnored private let debounce: Duration
    @ObservationIgnored private let sleep: @Sendable (Duration) async throws -> Void
    @ObservationIgnored private let now: () -> Date
    /// The area most recently asked for: being fetched, or fetched.
    @ObservationIgnored private var requestedArea: BoundingBox?
    @ObservationIgnored private var userLocation: Coordinate?
    /// The pending or running load. Internal so tests can await it.
    @ObservationIgnored private(set) var loadTask: Task<Void, Never>?

    public convenience init(source: any PubSource, debounce: Duration = .milliseconds(300)) {
        self.init(
            source: source,
            debounce: debounce,
            sleep: { duration in
                try await Task.sleep(for: duration)
            },
            now: { Date() }
        )
    }

    init(
        source: any PubSource,
        debounce: Duration,
        sleep: @escaping @Sendable (Duration) async throws -> Void,
        now: @escaping () -> Date
    ) {
        self.source = source
        self.debounce = debounce
        self.sleep = sleep
        self.now = now
    }

    /// Show the last list saved on disk, if nothing has been fetched yet: the app
    /// opens with something on screen, marked with its age, while it fetches.
    public func loadCached() async {
        guard fetchedAt == nil, let cached = await source.cachedPubs() else {
            return
        }
        // A fetch may have finished while the cache was being read.
        guard fetchedAt == nil else {
            return
        }
        pubs = PubOrdering.forDisplay(cached.value.pubs)
        fetchedAt = cached.fetchedAt
        isShowingCached = true
    }

    /// The map settled on a new area.
    public func areaChanged(to area: BoundingBox) {
        guard shouldFetch(area) else {
            return
        }
        load(area, debounced: true)
    }

    /// Fetch `area` only if nothing has been asked for yet: a fallback for when
    /// the map has not reported an area of its own.
    public func loadIfIdle(in area: BoundingBox) {
        guard requestedArea == nil else {
            return
        }
        load(area, debounced: false)
    }

    /// Fetch the current area again now, e.g. on returning to the foreground.
    public func refresh() {
        guard let area = requestedArea else {
            return
        }
        load(area, debounced: false)
    }

    /// The user's position changed. The first fix refetches, so distances appear.
    public func userLocationChanged(to location: Coordinate?) {
        let isFirstFix = userLocation == nil && location != nil
        userLocation = location
        if isFirstFix {
            refresh()
        }
    }

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

    private func load(_ area: BoundingBox, debounced: Bool) {
        loadTask?.cancel()
        requestedArea = area
        let location = userLocation
        loadTask = Task { [debounce, sleep] in
            do {
                if debounced {
                    try await sleep(debounce)
                }
                isLoading = true
                let list = try await source.fetchPubs(in: area, near: location)
                // A newer request may have started while this one was in flight.
                try Task.checkCancellation()
                pubs = PubOrdering.forDisplay(list.pubs)
                fetchedAt = now()
                isShowingCached = false
                lastError = nil
                isLoading = false
            } catch is CancellationError {
                // Superseded: the newer load owns `isLoading`. If nothing
                // superseded it, stop showing a spinner.
                if !Task.isCancelled {
                    isLoading = false
                }
            } catch let error as PubDBError {
                lastError = error
                isLoading = false
            } catch {
                lastError = .transport(URLError(.unknown))
                isLoading = false
            }
        }
    }
}
