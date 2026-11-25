import Foundation

/// The filters with more than an on/off: each opens a card under the pill row.
enum FilterPanel: String, Identifiable, CaseIterable {
    case kind, hours, features, rating, guinness

    var id: Self { self }
}
