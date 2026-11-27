import Foundation
import PubDBModels

/// What the operator picker offers for what's typed: the known operators
/// that contain it (ignoring case and accents), most pubs first as `/brands`
/// sends them, and whether the typed name is new.
struct OperatorMatches: Equatable {
    /// How many rows the picker shows at most.
    static let limit = 8

    let brands: [Brand]
    /// What would be saved as a new operator: the typed text, trimmed. Nil when
    /// nothing is typed or it's already one of the known names.
    let newName: String?

    init(typed: String, in all: [Brand], limit: Int = Self.limit) {
        let name = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            brands = Array(all.prefix(limit))
            newName = nil
            return
        }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        brands = Array(all.filter { $0.name.range(of: name, options: options) != nil }.prefix(limit))
        let isKnown = all.contains { $0.name.compare(name, options: options) == .orderedSame }
        newName = isKnown ? nil : name
    }
}
