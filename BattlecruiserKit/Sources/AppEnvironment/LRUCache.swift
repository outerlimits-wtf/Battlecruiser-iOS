import Foundation

/// A small in-memory cache that forgets the least recently stored entry once
/// it holds more than `limit`.
public struct LRUCache<Key: Hashable, Value> {
    public let limit: Int
    private var values: [Key: Value] = [:]
    /// Least recently stored first.
    private var order: [Key] = []

    public init(limit: Int) {
        self.limit = max(0, limit)
    }

    public subscript(key: Key) -> Value? {
        values[key]
    }

    public mutating func store(_ value: Value, for key: Key) {
        values[key] = value
        order.removeAll { $0 == key }
        order.append(key)
        while order.count > limit {
            values[order.removeFirst()] = nil
        }
    }

    public var count: Int { values.count }
}

extension LRUCache: Sendable where Key: Sendable, Value: Sendable {}
