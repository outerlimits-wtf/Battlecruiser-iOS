import Foundation

/// Which editor a contributable field needs.
public enum FieldKind: Hashable, Sendable, Decodable {
    /// Yes / No / Not sure.
    case tri
    case text
    case url
    case phone
    /// Pence, between the field's `min` and `max`.
    case price
    case hours
    /// A night's last orders or kicked-out time.
    case night
    /// A venue kind key.
    case amenity
    case previousName
    case status
    /// A short weekday from meta's `weekdays` ("Tue"): quiz and karaoke night.
    case weekday
    /// A kind this build doesn't know. The spec says to edit it as plain text.
    case other(String)

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = switch raw {
        case "tri": .tri
        case "text": .text
        case "url": .url
        case "phone": .phone
        case "price": .price
        case "hours": .hours
        case "night": .night
        case "amenity": .amenity
        case "previous_name": .previousName
        case "status": .status
        case "weekday": .weekday
        default: .other(raw)
        }
    }
}
