import Foundation
import PubDBModels

/// One day in the hours editor.
enum DayHours: Hashable {
    /// Nothing on record. Left out when saving, which the server reads as closed.
    case unset
    case closed
    /// Deliberately not known: sent as `unknown`, not left out.
    case unknown
    /// Every session, kept whole so editing the first never drops an evening one.
    case open([HoursSession])

    /// A new open day, before anyone has picked times.
    static let defaultSession = HoursSession(open: "12:00", close: "23:00")

    var kind: DayState? {
        switch self {
        case .unset: nil
        case .closed: .closed
        case .unknown: .unknown
        case .open: .open
        }
    }

    /// How the day reads in its row: the editor's own draft, not server text.
    var summary: String {
        switch self {
        case .unset: "Not set"
        case .closed: "Closed"
        case .unknown: "Don't know"
        case .open(let sessions):
            sessions.map { "\($0.open)–\($0.close ?? "late")" }.joined(separator: ", ")
        }
    }
}
