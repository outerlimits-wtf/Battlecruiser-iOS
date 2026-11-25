import Foundation

/// A field people can contribute, and how to edit it. Adding one on the server
/// must not need an app release, so editors are picked by `kind`, never by `key`.
public struct ContributableField: Decodable, Hashable, Sendable, Identifiable {
    public let key: String
    public let label: String
    public let kind: FieldKind
    /// True when repeating the current value counts as a confirmation (prices,
    /// night times). Otherwise a repeat is refused with `409 duplicate_value`.
    public let corroborating: Bool
    /// Bounds for `price` fields, in pence.
    public let min: Int?
    public let max: Int?

    public var id: String { key }

    private enum CodingKeys: String, CodingKey {
        case key, label, kind, corroborating, min, max
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        label = try container.decode(String.self, forKey: .label)
        kind = try container.decode(FieldKind.self, forKey: .kind)
        corroborating = try container.decodeIfPresent(Bool.self, forKey: .corroborating) ?? false
        min = try container.decodeIfPresent(Int.self, forKey: .min)
        max = try container.decodeIfPresent(Int.self, forKey: .max)
    }
}
