import Foundation

/// One piece of a structured field (S5): `status` is state, year and what it
/// became; `previous_name` is name, year and owner.
public struct FieldPart: Decodable, Hashable, Sendable, Identifiable {
    public let key: String
    /// "Year it stopped being called that".
    public let label: String
    /// `text`, `year`, or `status` (a state from the status list). Unknown
    /// kinds are edited as text.
    public let kind: String
    public let optional: Bool

    public var id: String { key }

    private enum CodingKeys: String, CodingKey {
        case key, label, kind, optional
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        label = try container.decode(String.self, forKey: .label)
        kind = try container.decode(String.self, forKey: .kind)
        optional = try container.decodeIfPresent(Bool.self, forKey: .optional) ?? true
    }
}
