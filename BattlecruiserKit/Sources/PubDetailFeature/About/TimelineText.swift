import Foundation
import PubDBModels

/// The words on a timeline stop, as the web puts them. S7 asks the server for
/// a ready-made `spanLabel`.
enum TimelineText {
    /// "1988–1997 The Old Larrik", or "1997– The Bedford (now)".
    static func title(_ stop: TimelineStop) -> String {
        let span: String? = switch (stop.fromLabel, stop.untilLabel) {
        case (nil, nil): nil
        case let (from, nil) where stop.isCurrent: "\(from ?? "?")–"
        case let (from, until): "\(from ?? "?")–\(until ?? "?")"
        }
        let name = stop.isCurrent ? "\(stop.name) (now)" : stop.name
        return [span, name].compactMap { $0 }.joined(separator: " ")
    }

    /// The owner, and who said so (never the importers' names).
    static func note(_ stop: TimelineStop) -> String? {
        let credit = stop.attribution.flatMap { $0.kind == "importer" ? nil : $0.label }
        let parts = [stop.owner, credit].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
