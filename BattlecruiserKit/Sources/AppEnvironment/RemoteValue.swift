import Foundation
import Observation

/// One thing a page shows from the server, loaded on appear and on pull to
/// refresh: the feed, the leaderboard, a board, a profile, a list.
@Observable
public final class RemoteValue<Value: Sendable> {
    public private(set) var state = Loadable<Value>()

    @ObservationIgnored private let fetch: @Sendable () async throws -> Value

    public init(fetch: @escaping @Sendable () async throws -> Value) {
        self.fetch = fetch
    }

    public var value: Value? { state.value }

    public func load() async {
        state.start()
        do {
            let fresh = try await fetch()
            state.succeed(fresh, at: Date())
        } catch {
            state.fail(error)
        }
    }
}
