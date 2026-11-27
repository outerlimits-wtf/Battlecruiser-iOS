import Foundation

/// What the door says. Every field is nil when the hours are unknown; the
/// object itself is still present.
public struct Hours: Decodable, Hashable, Sendable {
    /// The OpenStreetMap opening_hours string. For display only; never parse it.
    public let raw: String?
    public let source: String?
    public let attribution: Attribution?
}
