import Foundation
import PubDBModels

/// The states a pub can be in, copied from the web (`src/lib/types.ts`)
/// because `/meta` doesn't list them yet. **Temporary:** server ask S21 adds
/// `meta.statuses`; once it's deployed, draw from that and keep this only for
/// an older server (parity-plan.md, Phase H step 15).
struct StatusState: Identifiable, Hashable {
    let key: String
    let label: String
    let emoji: String
    /// About our record, not the pub: a second listing, or never a pub.
    let isListingError: Bool

    var id: String { key }

    static let all: [StatusState] = [
        StatusState(key: "open", label: "Open", emoji: "🍺", isListingError: false),
        StatusState(key: "temporarily_closed", label: "Shut for now", emoji: "🚧", isListingError: false),
        StatusState(key: "closed", label: "Closed down", emoji: "🪦", isListingError: false),
        StatusState(key: "demolished", label: "Demolished", emoji: "💥", isListingError: false),
        StatusState(key: "converted", label: "Converted", emoji: "🏢", isListingError: false),
        StatusState(key: "duplicate", label: "Duplicate listing", emoji: "👯", isListingError: true),
        StatusState(key: "broken", label: "Broken listing", emoji: "🚫", isListingError: true),
    ]

    static func isListingError(_ key: String) -> Bool {
        all.first { $0.key == key }?.isListingError ?? false
    }
}

/// The JSON object a structured value is sent as (S5): one key per part, in
/// meta's `parts`. A `year` part goes as a number, an empty optional part as
/// null. Nil when a required part is missing or a year isn't four digits.
enum StructuredValue {
    static func json(_ parts: [FieldPart], values: [String: String]) -> String? {
        var object: [String: Any] = [:]
        for part in parts {
            let raw = (values[part.key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if raw.isEmpty {
                guard part.optional else { return nil }
                object[part.key] = NSNull()
            } else if part.kind == "year" {
                guard raw.count == 4, let year = Int(raw) else { return nil }
                object[part.key] = year
            } else {
                guard !raw.contains("|") else { return nil }
                object[part.key] = raw
            }
        }
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
