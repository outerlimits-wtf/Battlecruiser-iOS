import Foundation

/// One fact a drinker added, ready to show.
public struct Contribution: Decodable, Hashable, Sendable, Identifiable {
    public let id: Int
    public let field: String
    public let fieldLabel: String
    /// The value as entered; show `displayValue`.
    public let value: String
    public let displayValue: String
    public let createdAt: String
    public let createdAtLabel: String
    public let attribution: Attribution
    public let canRemove: Bool
}
