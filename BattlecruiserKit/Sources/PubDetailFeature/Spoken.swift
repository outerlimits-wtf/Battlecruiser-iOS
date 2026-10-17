import Foundation
import PubDBModels

/// What VoiceOver says where the screen's text would read badly aloud.
///
/// The screen shows the server's labels as sent (decision D12). These only
/// rephrase them for speech: a grid of times read cell by cell means nothing,
/// "1h 24m" is read as letters, and an en dash is read as "dash".
public nonisolated enum Spoken {
    /// One night of the week table as a sentence:
    /// "Thursday, tonight: open 16:00 to 23:00, last orders 22:45, out not reported".
    public static func weekRow(_ row: WeekRow) -> String {
        let day = row.isTonight ? "\(row.dayLongLabel), tonight" : row.dayLongLabel
        let open = row.doorSays.map { "open " + range($0) } ?? "hours unknown"
        let bell = "last orders " + (row.bell?.label ?? "not reported")
        let out = "out " + (row.out?.label ?? "not reported")
        return "\(day): \(open), \(bell), \(out)"
    }

    /// Minutes until closing, in words: "1 hour, 24 minutes".
    public static func countdown(minutes: Int, locale: Locale = .current) -> String {
        Duration.seconds(minutes * 60).formatted(
            .units(allowed: [.hours, .minutes], width: .wide).locale(locale)
        )
    }

    /// "12:00–23:00" → "12:00 to 23:00".
    private static func range(_ text: String) -> String {
        text.replacingOccurrences(of: "–", with: " to ")
    }
}
