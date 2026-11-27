import Foundation
import PubDBModels

/// The text lines of a pub card, as the web's `PubCard` builds them: the
/// server's labels joined with " · ". Kept apart from the view so it is tested.
enum PubCardLines {
    static let separator = " · "

    /// Kind and area. The rating (with its coloured star) goes before it and
    /// the Guinness price after; the brand sits by the name.
    static func summary(_ pub: PubSummary) -> String {
        var parts = [pub.amenity.label]
        if let area = pub.area { parts.append(area) }
        return parts.joined(separator: separator)
    }

    /// For a pub that isn't trading: "Closed 2019 · now a Tesco Express".
    static func status(_ status: PubStatus) -> String {
        var line = status.label
        if let since = status.since { line += " \(since)" }
        if let became = status.became { line += "\(separator)now \(became)" }
        return line
    }

    /// Tonight and distance, after the hours pill.
    static func extras(_ pub: PubSummary) -> String? {
        let parts = [pub.tonight?.label, pub.distance?.label].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: separator)
    }

    /// "Listed", then the first three features.
    static func features(_ pub: PubSummary) -> String? {
        let parts = (pub.listed ? ["Listed"] : []) + pub.features.prefix(3).map(\.label)
        return parts.isEmpty ? nil : parts.joined(separator: separator)
    }

    /// Not serving, or closed right now: the row fades back.
    static func isShut(_ pub: PubSummary) -> Bool {
        !pub.status.serving || pub.open.state == .closed
    }
}
