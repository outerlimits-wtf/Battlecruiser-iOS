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
    /// Which part of the Fix panel it goes in (S4). Nil from an older server.
    public let section: FieldSection?
    /// Its place across every section, lower first.
    public let order: Int?
    /// Hint text for an empty input; nil where there is no free input.
    public let placeholder: String?
    /// The longest value accepted by a free-text editor.
    public let maxLength: Int?
    /// The pieces of a structured value (`status`, `previous_name`; S5), in order.
    public let parts: [FieldPart]

    public var id: String { key }

    private enum CodingKeys: String, CodingKey {
        case key, label, kind, corroborating, min, max, section, order, placeholder, maxLength, parts
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        label = OperatorLabel.label(try container.decode(String.self, forKey: .label), forKey: key, keys: ["brand"])
        kind = try container.decode(FieldKind.self, forKey: .kind)
        corroborating = try container.decodeIfPresent(Bool.self, forKey: .corroborating) ?? false
        min = try container.decodeIfPresent(Int.self, forKey: .min)
        max = try container.decodeIfPresent(Int.self, forKey: .max)
        section = try? container.decodeIfPresent(FieldSection.self, forKey: .section)
        order = try? container.decodeIfPresent(Int.self, forKey: .order)
        placeholder = try? container.decodeIfPresent(String.self, forKey: .placeholder)
        maxLength = try? container.decodeIfPresent(Int.self, forKey: .maxLength)
        parts = (try? container.decodeIfPresent([FieldPart].self, forKey: .parts)) ?? []
    }
}
