import Foundation

/// Why something is being reported. Offer only the reasons whose `types`
/// include the thing being reported.
public struct ReportReason: Decodable, Hashable, Sendable, Identifiable {
    public let key: String
    public let label: String
    /// "photo", "review", "contribution".
    public let types: [String]

    public var id: String { key }

    public func applies(to type: String) -> Bool {
        types.contains(type)
    }
}
