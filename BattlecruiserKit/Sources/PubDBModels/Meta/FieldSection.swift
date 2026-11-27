import Foundation

/// Where a contributable field's editor goes in the Fix panel (S4).
public enum FieldSection: Hashable, Sendable, Decodable {
    case details
    case features
    case tonight
    case history
    case listing
    /// A section this build doesn't know: drawn after the others, under its key.
    case other(String)

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = switch raw {
        case "details": .details
        case "features": .features
        case "tonight": .tonight
        case "history": .history
        case "listing": .listing
        default: .other(raw)
        }
    }
}
