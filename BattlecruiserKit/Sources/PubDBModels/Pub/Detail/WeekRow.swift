import Foundation

public struct WeekRow: Decodable, Hashable, Sendable, Identifiable {
    /// 0 = Monday.
    public let day: Int
    public let dayLabel: String
    public let dayLongLabel: String
    public let isTonight: Bool
    /// Opening hours for the day, e.g. "12:00–23:00"; nil when unknown.
    public let doorSays: String?
    /// `doorSays` as data, for the hours editor (S2). Nil when the pub has no
    /// hours at all, and from an older server.
    public let state: DayState?
    /// Every session that day; empty unless `state` is `.open`.
    public let sessions: [HoursSession]
    /// When last orders is called, from drinkers' reports.
    public let bell: NightFigure?
    /// When people are turned out, from drinkers' reports.
    public let out: NightFigure?

    public var id: Int { day }

    private enum CodingKeys: String, CodingKey {
        case day, dayLabel, dayLongLabel, isTonight, doorSays, state, sessions, bell, out
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        day = try container.decode(Int.self, forKey: .day)
        dayLabel = try container.decode(String.self, forKey: .dayLabel)
        dayLongLabel = try container.decode(String.self, forKey: .dayLongLabel)
        isTonight = try container.decode(Bool.self, forKey: .isTonight)
        doorSays = try container.decodeIfPresent(String.self, forKey: .doorSays)
        state = try? container.decodeIfPresent(DayState.self, forKey: .state)
        sessions = (try? container.decodeIfPresent([HoursSession].self, forKey: .sessions)) ?? []
        bell = try container.decodeIfPresent(NightFigure.self, forKey: .bell)
        out = try container.decodeIfPresent(NightFigure.self, forKey: .out)
    }
}
