import Foundation
import PubDBModels

/// The hours editor's week, Monday first, read from `weekTable[].state` and
/// `sessions` and sent back as the structured `opening_hours` value (S2).
/// Neither direction touches OSM syntax.
struct WeekHours: Equatable {
    var days: [DayHours]
    /// "Monday"…, from the week table.
    let names: [String]

    init(weekTable: [WeekRow]) {
        var days = Array(repeating: DayHours.unset, count: 7)
        var names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        for row in weekTable where (0..<7).contains(row.day) {
            names[row.day] = row.dayLongLabel
            days[row.day] = switch row.state {
            case .open where !row.sessions.isEmpty: .open(row.sessions)
            case .closed: .closed
            case .unknown: .unknown
            default: .unset
            }
        }
        self.days = days
        self.names = names
    }

    /// Whether every day is still unset: nothing to send.
    var isEmpty: Bool { days.allSatisfy { $0 == .unset } }

    /// The `opening_hours` value as a JSON string, `{ "days": [...] }`.
    /// Unset days are left out. Nil when there is nothing to send.
    var value: String? {
        guard !isEmpty else { return nil }
        let payload = Payload(days: days.enumerated().compactMap { index, day in
            switch day {
            case .unset: nil
            case .closed: Payload.Day(day: index, state: .closed, sessions: nil)
            case .unknown: Payload.Day(day: index, state: .unknown, sessions: nil)
            case .open(let sessions): Payload.Day(day: index, state: .open, sessions: sessions)
            }
        })
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(payload) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Give every day the same hours as `index`.
    mutating func copyToEveryDay(from index: Int) {
        days = Array(repeating: days[index], count: 7)
    }

    private struct Payload: Encodable {
        struct Day: Encodable {
            let day: Int
            let state: DayState
            let sessions: [HoursSession]?
        }
        let days: [Day]
    }
}
