import Foundation

/// How a day's hours stand (S2).
public enum DayState: String, Codable, Hashable, Sendable {
    case open
    /// Left out of the hours, or `off`.
    case closed
    /// Marked as not known.
    case unknown
}
