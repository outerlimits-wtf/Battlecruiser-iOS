import Foundation

/// Tonight's last orders or kicked-out time. `minutes` can exceed 1440 and
/// `label` can read "24:40"; both are deliberate, so show `label` as sent.
public struct Tonight: Decodable, Hashable, Sendable {
    /// "kicked_out" or "last_orders".
    public let kind: String
    public let label: String
    public let symbol: Symbol
    public let minutes: Int
    public let reports: Int
}
