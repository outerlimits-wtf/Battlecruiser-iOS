import Foundation

/// Open or closed at the moment the request's `at` named. Goes stale with the clock.
public struct OpenInfo: Decodable, Hashable, Sendable {
    public let state: OpenState
    /// Pill text: "Closes 23:00", "Closed", "Hours unknown".
    public let label: String
    /// Wall-clock minute of the closing day (60 = 01:00). Never subtract this from
    /// the clock; count down `minutesUntilClose` instead.
    public let closesAt: Int?
    public let closesAtLabel: String?
    public let minutesUntilClose: Int?
    /// "1h 24m", "15 min". Nil unless open.
    public let countdownLabel: String?
    /// Within an hour of closing.
    public let closingSoon: Bool
}
