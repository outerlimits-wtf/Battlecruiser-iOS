import Foundation

public enum OpenState: String, Decodable, Hashable, Sendable {
    case open
    case closed
    /// No hours on record. Must not be drawn as either open or closed.
    case unknown

    /// Any state the server adds later is treated as unknown rather than failing.
    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = OpenState(rawValue: raw) ?? .unknown
    }
}
