import Foundation
import Testing
import PubDBModels
@testable import PubDetailFeature

/// The hours editor reads `weekTable[].state`/`sessions` and sends `{ days }` (S2).
@MainActor
struct WeekHoursTests {
    private func rows(_ json: String) throws -> [WeekRow] {
        try JSONDecoder().decode([WeekRow].self, from: Data(json.utf8))
    }

    private func row(_ day: Int, _ rest: String) -> String {
        #"{"day": \#(day), "dayLabel": "D\#(day)", "dayLongLabel": "Day \#(day)", "isTonight": false, "doorSays": null, \#(rest)}"#
    }

    @Test func readsEachDaysStateAndKeepsEverySession() throws {
        let table = try rows("[" + [
            row(0, #""state": "open", "sessions": [{"open": "12:00", "close": "15:00"}, {"open": "18:00", "close": null}]"#),
            row(1, #""state": "closed", "sessions": []"#),
            row(2, #""state": "unknown", "sessions": []"#),
            row(3, #""state": null, "sessions": []"#),
        ].joined(separator: ",") + "]")
        let week = WeekHours(weekTable: table)

        #expect(week.days[0] == .open([HoursSession(open: "12:00", close: "15:00"), HoursSession(open: "18:00", close: nil)]))
        #expect(week.days[1] == .closed)
        #expect(week.days[2] == .unknown)
        #expect(week.days[3] == .unset)
        #expect(week.days[6] == .unset)
        #expect(week.names[0] == "Day 0")
        #expect(week.names[6] == "Sunday")
    }

    @Test func olderServersWithNoStateLeaveEveryDayUnset() throws {
        let week = WeekHours(weekTable: try rows("[" + row(0, #""bell": null"#) + "]"))
        #expect(week.isEmpty)
        #expect(week.value == nil)
    }

    @Test func sendsTheWeekLeavingUnsetDaysOut() throws {
        var week = WeekHours(weekTable: [])
        week.days[0] = .open([HoursSession(open: "12:00", close: "01:00")])
        week.days[5] = .open([HoursSession(open: "20:00", close: nil)])
        week.days[6] = .unknown

        #expect(week.value == #"{"days":[{"day":0,"sessions":[{"close":"01:00","open":"12:00"}],"state":"open"},{"day":5,"sessions":[{"close":null,"open":"20:00"}],"state":"open"},{"day":6,"state":"unknown"}]}"#)
    }

    @Test func copiesOneDayToEveryDay() {
        var week = WeekHours(weekTable: [])
        week.days[2] = .open([DayHours.defaultSession])
        week.copyToEveryDay(from: 2)
        #expect(week.days.allSatisfy { $0 == .open([DayHours.defaultSession]) })
    }

    @Test func timesSplitAndJoinAsHoursAndMinutes() {
        #expect(TimeStepPicker.parts("23:45") == (23, 45))
        #expect(TimeStepPicker.parts("24:00") == (0, 0))
        #expect(TimeStepPicker.parts("nonsense") == (0, 0))
        #expect(TimeStepPicker.format(1, 5) == "01:05")
        #expect(TimeStepPicker.step == 5)
    }
}

/// Night fields go as "Thu 23:15" or `{ "at": … }` (S3); no 06:00 maths here.
@MainActor
struct NightReportTests {
    @Test func aPickedNightIsTheWeekdayThenTheTime() {
        #expect(NightReport.value(night: "Thu", time: "00:30") == "Thu 00:30")
    }

    @Test func justNowSendsTheInstant() {
        let value = NightReport.justNow(Date(timeIntervalSince1970: 1_788_000_000))
        #expect(value == #"{"at":"2026-08-29T10:40:00Z"}"#)
    }

    @Test func gardenTimesAreHoursAndMinutes() {
        #expect(SingleTimeEditor.isTime("21:30"))
        #expect(!SingleTimeEditor.isTime("With the pub"))
    }
}
