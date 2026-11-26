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
    public internal(set) var pubs: [PubSummary] = []
    public internal(set) var isLoading = false
    /// The last fetch's failure, cleared by the next success. `pubs` is kept.
    public internal(set) var lastError: PubDBError? = nil
    /// When `pubs` was fetched. Open states are true only for that moment.
    public internal(set) var fetchedAt: Date? = nil
    /// True while `pubs` came from the disk cache rather than this session's fetch.
    public internal(set) var isShowingCached = false

    /// How many of `pubs` can serve you right now.
    public var openCount: Int {
        pubs.filter { PubOrdering.rank($0) == 0 }.count
    }

    /// What, if anything, the screen should tell the user about these pubs.
    public var notice: PubsNotice? {
        PubsNotice.current(
            area: query.usesArea ? requestedArea : nil,
            pubCount: pubs.count,
            hasFreshResult: fetchedAt != nil && !isShowingCached,
            isLoading: isLoading,
            error: lastError
        )
    }

    @ObservationIgnored let source: any PubSource
    @ObservationIgnored let debounce: Duration
    @ObservationIgnored let sleep: @Sendable (Duration) async throws -> Void
    @ObservationIgnored let now: () -> Date
    /// The area most recently asked for: being fetched, or fetched.
    public internal(set) var requestedArea: BoundingBox? = nil
    /// The search and filters the list is for.
    public internal(set) var query = PubQuery()
    @ObservationIgnored var userLocation: Coordinate?
    /// The pending or running load. Internal so tests can await it.
    @ObservationIgnored var loadTask: Task<Void, Never>?

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
        pubs = PubOrdering.forDisplay(cached.value.pubs, keepingServerOrder: query.latestClose)
        fetchedAt = cached.fetchedAt
        isShowingCached = true
    }

    /// The map settled on a new area. A search or "everywhere" ignores it.
    public func areaChanged(to area: BoundingBox) {
        guard query.usesArea else {
            requestedArea = area
            return
        }
        guard shouldFetch(area) else {
            return
        }
        load(area, debounced: true)
    }

    /// The search or filters changed: fetch again with them.
    public func queryChanged(_ query: PubQuery) {
        guard query != self.query else { return }
        self.query = query
        lastError = nil
        load(requestedArea, debounced: true)
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
        guard requestedArea != nil || !query.usesArea else {
            return
        }
        load(requestedArea, debounced: false)
    }

    /// The user's position changed. The first fix refetches, so distances appear.
    public func userLocationChanged(to location: Coordinate?) {
        let isFirstFix = userLocation == nil && location != nil
        userLocation = location
        if isFirstFix {
            refresh()
        }
    }
}
