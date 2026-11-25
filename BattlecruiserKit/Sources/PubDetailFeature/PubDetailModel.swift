import Foundation
import Observation
import AppEnvironment
import PubDBClient
import PubDBModels

/// The pub the user has tapped, and its full detail.
///
/// Selecting a pub shows its summary at once (the sheet never opens empty),
/// shows a cached detail at once if this pub was opened recently, and fetches
/// a fresh one, because open state and "tonight" change with the clock.
/// Switching pubs cancels the previous fetch. A failed fetch keeps whatever is
/// already shown.
@Observable
public final class PubDetailModel {
    /// The summary the user tapped, when there was one (a list row). Shown
    /// until the detail arrives.
    public private(set) var selected: PubSummary? = nil
    /// The selected pub's id, however it was chosen.
    public private(set) var selectedID: String? = nil
    /// The name to show while nothing else is known, when the pub was chosen
    /// from a map pin, which carries no summary.
    public private(set) var placeholderName: String? = nil
    /// The full detail for `selected`: cached, then fresh. Nil until either exists.
    public private(set) var detail: PubDetail? = nil
    public private(set) var isLoading = false
    /// The last fetch's failure, cleared by the next selection or success.
    public private(set) var lastError: PubDBError? = nil
    /// When the shown detail was fetched, while it comes from the disk cache;
    /// nil once this session's fetch arrives.
    public private(set) var showingCachedFrom: Date? = nil

    /// The best summary available: the fresh one inside the detail, else the tapped one.
    public var summary: PubSummary? {
        detail?.summary ?? selected
    }

    @ObservationIgnored private let source: any PubDetailSource
    /// Recently fetched details, so reopening a pub shows it at once.
    @ObservationIgnored private var cache: LRUCache<String, PubDetail>
    @ObservationIgnored private var location: Coordinate?
    /// The running fetch. Internal so tests can await it.
    @ObservationIgnored private(set) var loadTask: Task<Void, Never>?

    /// - Parameters:
    ///   - source: Where details come from; the app passes its `PubDBClient`.
    ///   - cacheLimit: How many recently opened pubs to keep in memory.
    public init(source: any PubDetailSource, cacheLimit: Int = 50) {
        self.source = source
        cache = LRUCache(limit: cacheLimit)
    }

    /// Show `pub`, and fetch its full detail. Pass the user's location for distances.
    public func select(_ pub: PubSummary, near location: Coordinate?) {
        start(id: pub.id, summary: pub, name: pub.name, near: location)
    }

    /// Show the pub with this id, e.g. from a map pin: its name at once, the
    /// rest when the detail arrives.
    public func select(id: String, name: String, near location: Coordinate?) {
        start(id: id, summary: nil, name: name, near: location)
    }

    private func start(id: String, summary: PubSummary?, name: String, near location: Coordinate?) {
        loadTask?.cancel()
        selected = summary
        selectedID = id
        placeholderName = name
        detail = cache[id]
        showingCachedFrom = nil
        lastError = nil
        isLoading = false
        self.location = location
        load(id: id)
    }

    /// Fetch the selected pub again, e.g. on returning to the foreground, when
    /// its open state may have changed. Does nothing with no pub selected.
    public func refresh() {
        retry()
    }

    /// Fetch the selected pub again, e.g. after a failure.
    public func retry() {
        guard let id = selectedID else {
            return
        }
        loadTask?.cancel()
        lastError = nil
        load(id: id)
    }

    /// The sheet was dismissed.
    public func deselect() {
        loadTask?.cancel()
        loadTask = nil
        selected = nil
        selectedID = nil
        placeholderName = nil
        detail = nil
        showingCachedFrom = nil
        isLoading = false
        lastError = nil
    }

    // MARK: - Loading

    private func load(id: String) {
        let location = location
        loadTask = Task {
            // Superseded before it started: leave the state to the newer fetch.
            guard !Task.isCancelled else {
                return
            }
            // Nothing in memory: show the copy saved on disk while fetching.
            if detail == nil, let saved = await source.cachedPub(id: id) {
                guard !Task.isCancelled else {
                    return
                }
                detail = saved.value
                showingCachedFrom = saved.fetchedAt
            }
            isLoading = true
            do {
                let fresh = try await source.fetchPub(id: id, near: location)
                try Task.checkCancellation()
                cache.store(fresh, for: fresh.id)
                detail = fresh
                showingCachedFrom = nil
                isLoading = false
            } catch {
                // A cancellation is a newer fetch taking over: leave it the state.
                if let shown = PubDBError.wrapping(error) {
                    lastError = shown
                    isLoading = false
                } else if !Task.isCancelled {
                    isLoading = false
                }
            }
        }
    }
}
