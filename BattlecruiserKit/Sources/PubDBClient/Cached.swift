import Foundation

/// A value read back from the cache, and when the server sent it.
public struct Cached<Value: Sendable>: Sendable {
    public let value: Value
    public let fetchedAt: Date

    public init(value: Value, fetchedAt: Date) {
        self.value = value
        self.fetchedAt = fetchedAt
    }
}
