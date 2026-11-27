import Foundation

extension PubsModel {
    /// Refetch the current area every `interval` until cancelled. Run it from
    /// `.task(id:)` so it restarts when the interval changes, e.g. when a pub
    /// nears closing.
    public func refreshPeriodically(every interval: Duration) async {
        while !Task.isCancelled {
            try? await Task.sleep(for: interval)
            guard !Task.isCancelled else { return }
            refresh()
        }
    }
}
