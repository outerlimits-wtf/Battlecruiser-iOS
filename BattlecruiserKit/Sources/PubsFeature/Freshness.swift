import Foundation
import PubDBModels

/// When what's on screen is too old to trust, and how often to replace it.
///
/// "Open", "closes in 20 min" and "tonight" are true only for the moment they
/// were fetched (docs/backend/04-ios-integration.md, "Open now goes stale").
/// Rather than counting down on the device, the app refetches and says how old
/// the data is.
public nonisolated enum Freshness {
    /// Older than this, the screen says "As of 22:41".
    public static let staleAfter: TimeInterval = 5 * 60

    /// Whether data fetched at `fetchedAt` should be labelled as old at `now`.
    /// Nothing fetched yet means nothing to label.
    public static func isStale(fetchedAt: Date?, now: Date) -> Bool {
        guard let fetchedAt else {
            return false
        }
        return now.timeIntervalSince(fetchedAt) > staleAfter
    }

    /// How long to wait before refetching: every minute while any pub on screen
    /// is about to close, otherwise every five.
    public static func refreshInterval(for pubs: [PubSummary]) -> Duration {
        let anyClosingSoon = pubs.contains { $0.open.closingSoon }
        return anyClosingSoon ? .seconds(60) : .seconds(5 * 60)
    }
}
