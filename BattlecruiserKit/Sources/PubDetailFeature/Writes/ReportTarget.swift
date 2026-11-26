import Foundation

/// What a report is about: a photo, review or contribution, by id.
struct ReportTarget: Identifiable, Hashable {
    let type: String
    let id: String
}
