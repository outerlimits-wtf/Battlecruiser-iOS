import Foundation
import Testing
import PubDBModels
@testable import PubDetailFeature

/// What VoiceOver says for the week table and the closing countdown.
struct SpokenTests {
    @Test func aNightWithEverythingReportedReadsAsOneSentence() {
        let row = weekRow(day: "Thursday", tonight: true, door: "16:00–23:00", bell: "22:45", out: "23:20")

        let spoken = Spoken.weekRow(row)

        #expect(spoken == "Thursday, tonight: open 16:00 to 23:00, last orders 22:45, out 23:20")
    }

    @Test func missingTimesAreSaidNotSkipped() {
        let row = weekRow(day: "Monday", tonight: false, door: nil, bell: nil, out: nil)

        let spoken = Spoken.weekRow(row)

        #expect(spoken == "Monday: hours unknown, last orders not reported, out not reported")
    }

    @Test func pastMidnightTimesAreReadAsSent() {
        let row = weekRow(day: "Friday", tonight: false, door: "12:00–01:00", bell: nil, out: "24:40")

        let spoken = Spoken.weekRow(row)

        #expect(spoken == "Friday: open 12:00 to 01:00, last orders not reported, out 24:40")
    }

    @Test func theCountdownIsInWords() {
        let british = Locale(identifier: "en_GB")

        let mixed = Spoken.countdown(minutes: 84, locale: british)
        let minutesOnly = Spoken.countdown(minutes: 15, locale: british)

        #expect(mixed.contains("1 hour"))
        #expect(mixed.contains("24 minutes"))
        #expect(minutesOnly.contains("15 minutes"))
        #expect(!minutesOnly.contains("hour"))
    }

    // MARK: - Helpers

    /// A week-table row as the server sends one.
    private func weekRow(day: String, tonight: Bool, door: String?, bell: String?, out: String?) -> WeekRow {
        func figure(_ label: String?) -> String {
            guard let label else {
                return "null"
            }
            return #"{ "minutes": 1380, "label": "\#(label)", "reports": 1, "latestAt": "2026-10-01", "latestLabel": "1 Oct 2026" }"#
        }
        let doorJSON = door.map { "\"\($0)\"" } ?? "null"
        let json = #"""
        { "day": 3, "dayLabel": "\#(day.prefix(3))", "dayLongLabel": "\#(day)", "isTonight": \#(tonight),
          "doorSays": \#(doorJSON), "bell": \#(figure(bell)), "out": \#(figure(out)) }
        """#
        return try! JSONDecoder().decode(WeekRow.self, from: Data(json.utf8))
    }
}
