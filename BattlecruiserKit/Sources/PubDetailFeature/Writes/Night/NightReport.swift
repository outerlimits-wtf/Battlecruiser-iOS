import Foundation

/// The two values a night field (`last_orders`, `kicked_out`) takes (S3), so
/// the device never works out which night 00:30 belongs to.
enum NightReport {
    /// A picked night: meta's short weekday for the night the session
    /// started, then the time. Half past midnight after Thursday is "Thu 00:30".
    static func value(night short: String, time: String) -> String {
        "\(short) \(time)"
    }

    /// "It just happened": the instant, which the server files on its night.
    static func justNow(_ date: Date = .now) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return #"{"at":"\#(formatter.string(from: date))"}"#
    }
}
