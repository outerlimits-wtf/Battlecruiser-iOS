import Foundation

public struct Guinness: Decodable, Hashable, Sendable {
    public let pence: Int
    /// "£6.20".
    public let formatted: String
    public let reports: Int
    public let updatedAt: String
    /// "a month ago", relative to the request's `at`.
    public let agoLabel: String
}
