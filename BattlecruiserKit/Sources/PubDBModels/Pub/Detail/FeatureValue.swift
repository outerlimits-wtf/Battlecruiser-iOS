import Foundation

public enum FeatureValue: String, Decodable, Hashable, Sendable {
    case yes
    case no
    case unknown

    /// Any answer the server adds later is treated as unknown rather than failing.
    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = FeatureValue(rawValue: raw) ?? .unknown
    }
}
