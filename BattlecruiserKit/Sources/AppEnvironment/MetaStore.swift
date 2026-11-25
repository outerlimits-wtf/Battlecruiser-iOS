import Foundation
import Observation
import PubDBClient
import PubDBModels

/// The server's lists, labels and limits (`GET /meta`) for the whole app.
///
/// On launch it shows the copy saved last time at once, then fetches a fresh
/// one; on returning to the foreground it fetches again. Screens read `meta`
/// and draw nothing that depends on it until it is there.
@Observable
public final class MetaStore {
    public private(set) var state = Loadable<Meta>()

    public var meta: Meta? { state.value }

    @ObservationIgnored private let source: any MetaSource
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private(set) var loadTask: Task<Void, Never>?

    public init(source: any MetaSource, now: @escaping () -> Date = { Date() }) {
        self.source = source
        self.now = now
    }

    /// The saved copy now, then a fresh fetch.
    public func load() {
        loadTask?.cancel()
        loadTask = Task {
            if state.value == nil, let saved = await source.cachedMeta() {
                state.showCached(saved.value, fetchedAt: saved.fetchedAt)
            }
            await fetch()
        }
    }

    /// Fetch again, e.g. on returning to the foreground.
    public func refresh() {
        loadTask?.cancel()
        loadTask = Task { await fetch() }
    }

    /// Whether the server has retired this build (`clients.ios.minVersion`).
    /// False until `/meta` is known, so the app is never blocked by a slow network.
    public func requiresUpdate(from build: AppVersion?) -> Bool {
        guard let build, let meta else { return false }
        return !build.isAllowed(minimum: meta.clients.ios.minVersion)
    }

    private func fetch() async {
        state.start()
        do {
            let fresh = try await source.fetchMeta()
            try Task.checkCancellation()
            state.succeed(fresh, at: now())
        } catch {
            state.fail(error)
        }
    }
}
