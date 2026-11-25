import Foundation

/// A reported time for one night: the median of the last two years of reports.
public struct NightFigure: Decodable, Hashable, Sendable {
    public let minutes: Int
    /// May read "24:40" past midnight; show as sent.
    public let label: String
    public let reports: Int
    public let latestAt: String
    public let latestLabel: String
}
