import Foundation
import PubDBClient

/// Something fetched from the server, as a screen shows it: the value it has
/// (kept through a failure, so the screen never blanks), whether a fetch is
/// running, the last failure, and when the value was fetched.
public struct Loadable<Value> {
    public var value: Value?
    public var isLoading = false
    /// The last failure, cleared by the next success. `value` is kept.
    public var error: PubDBError?
    /// When `value` was fetched. Open states in it are true only for that moment.
    public var fetchedAt: Date?
    /// True while `value` is a copy from the disk cache, not this session's fetch.
    public var isFromCache = false

    public init(value: Value? = nil) {
        self.value = value
    }

    public mutating func start() {
        isLoading = true
    }

    public mutating func succeed(_ value: Value, at date: Date) {
        self.value = value
        fetchedAt = date
        isFromCache = false
        error = nil
        isLoading = false
    }

    /// Show a saved copy, unless something fresher already arrived.
    public mutating func showCached(_ value: Value, fetchedAt date: Date) {
        guard self.value == nil || isFromCache else { return }
        self.value = value
        fetchedAt = date
        isFromCache = true
    }

    /// Record what a fetch threw. A cancellation only stops the spinner.
    public mutating func fail(_ thrown: any Error) {
        isLoading = false
        if let wrapped = PubDBError.wrapping(thrown) {
            error = wrapped
        }
    }
}

extension Loadable: Sendable where Value: Sendable {}
extension Loadable: Equatable where Value: Equatable {}
