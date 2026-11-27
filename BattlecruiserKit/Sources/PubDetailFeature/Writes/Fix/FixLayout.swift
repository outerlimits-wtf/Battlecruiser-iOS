import Foundation
import PubDBModels

/// The Fix panel's shape, from `/meta` and the pub (S4): which fields go in
/// which section, in what order, and what each holds now. Nothing here knows a
/// field by its key, so a field added on the server shows up without a release.
struct FixLayout: Equatable {
    struct Item: Equatable, Identifiable {
        let field: ContributableField
        /// What the pub has now; nil when the server didn't say (an older
        /// server, or a report field with only something to add).
        let current: EditableValue?

        var id: String { field.key }
    }

    struct Group: Equatable, Identifiable {
        let section: FieldSection
        let items: [Item]

        var id: String { FixLayout.key(section) }
        var title: String { FixLayout.title(section) }
    }

    let groups: [Group]

    /// Fields sorted by `order` (lower first; those without one after, in
    /// meta's order), grouped by `section`. Sections come in the order of their
    /// first field, and ones this build doesn't know go after the known ones.
    /// A field with no section (an older server) goes in Details.
    ///
    /// History is left out: editing it belongs on the timeline (H11).
    init(fields: [ContributableField], editable: [String: EditableValue]) {
        let sorted = fields.enumerated().sorted { lhs, rhs in
            switch (lhs.element.order, rhs.element.order) {
            case let (l?, r?) where l != r: l < r
            case (_?, nil): true
            case (nil, _?): false
            default: lhs.offset < rhs.offset
            }
        }.map(\.element)

        var sections: [FieldSection] = []
        var items: [FieldSection: [Item]] = [:]
        for field in sorted {
            let section = field.section ?? .details
            guard section != .history else { continue }
            if items[section] == nil { sections.append(section) }
            items[section, default: []].append(Item(field: field, current: editable[field.key]))
        }
        let known = sections.filter { !Self.isUnknown($0) }
        let unknown = sections.filter(Self.isUnknown)
        groups = (known + unknown).map { Group(section: $0, items: items[$0] ?? []) }
    }

    private static func isUnknown(_ section: FieldSection) -> Bool {
        if case .other = section { true } else { false }
    }

    static func key(_ section: FieldSection) -> String {
        switch section {
        case .details: "details"
        case .features: "features"
        case .tonight: "tonight"
        case .history: "history"
        case .listing: "listing"
        case .other(let raw): raw
        }
    }

    /// The heading over a section. An unknown one is headed by its key,
    /// made readable ("opening_times" → "Opening times").
    static func title(_ section: FieldSection) -> String {
        switch section {
        case .details: "Details"
        case .features: "What's there"
        case .tonight: "Tonight"
        case .history: "History"
        case .listing: "Listing"
        case .other(let raw):
            readable(raw)
        }
    }

    private static func readable(_ raw: String) -> String {
        let words = raw.replacingOccurrences(of: "_", with: " ")
        return words.prefix(1).uppercased() + String(words.dropFirst())
    }
}
