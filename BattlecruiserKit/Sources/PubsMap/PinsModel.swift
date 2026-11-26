import Foundation
import Observation
import PubDBClient
import PubDBModels

/// Every pin on the map, for the current filters.
///
/// Fetched when the filters change and then once a minute with `If-None-Match`,
/// never because the map moved (spec, "Building a map"). A `304` changes
/// nothing: `pins` is not even reassigned, so the map has nothing to redraw.
@Observable
public final class PinsModel {
    /// Quietest first, as the server sends them.
    public private(set) var pins: [Pin] = []
    public private(set) var isLoading = false
    /// The last failure, cleared by the next success. `pins` is kept.
    public private(set) var lastError: PubDBError?
    /// When the server last confirmed `pins`, by a new body or a `304`.
    public private(set) var confirmedAt: Date?

    @ObservationIgnored private let source: any PinsSource
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private var query: PubQuery
    @ObservationIgnored private(set) var loadTask: Task<Void, Never>?

    public init(source: any PinsSource, query: PubQuery = PubQuery(), now: @escaping () -> Date = { Date() }) {
        self.source = source
        self.query = query
        self.now = now
    }

    /// The filters changed: fetch for the new ones. The old pins stay until
    /// the new ones arrive.
    public func queryChanged(_ query: PubQuery) {
        guard query != self.query else { return }
        self.query = query
        refresh()
    }

    /// Ask again now; most answers are `304`.
    public func refresh() {
        loadTask?.cancel()
        let query = query
        loadTask = Task {
            isLoading = true
            do {
                let answer = try await source.fetchPins(matching: query)
                try Task.checkCancellation()
                if case .changed(let collection) = answer {
                    pins = collection.pins
                }
                confirmedAt = now()
                lastError = nil
                isLoading = false
            } catch {
                if let shown = PubDBError.wrapping(error) {
                    lastError = shown
                    isLoading = false
                } else if !Task.isCancelled {
                    isLoading = false
                }
            }
        }
    }

    /// Refresh every `interval` until cancelled; run it from `.task`.
    public func refreshPeriodically(every interval: Duration = .seconds(60)) async {
        while !Task.isCancelled {
            try? await Task.sleep(for: interval)
            guard !Task.isCancelled else { return }
            refresh()
        }
    }
}
