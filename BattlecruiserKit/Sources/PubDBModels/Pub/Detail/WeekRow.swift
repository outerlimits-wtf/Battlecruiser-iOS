import Foundation

public struct WeekRow: Decodable, Hashable, Sendable, Identifiable {
    /// 0 = Monday.
    public let day: Int
    public let dayLabel: String
    public let dayLongLabel: String
    public let isTonight: Bool
    /// Opening hours for the day, e.g. "12:00–23:00"; nil when unknown.
    public let doorSays: String?
    /// When last orders is called, from drinkers' reports.
    public let bell: NightFigure?
    /// When people are turned out, from drinkers' reports.
    public let out: NightFigure?

    public var id: Int { day }
}
