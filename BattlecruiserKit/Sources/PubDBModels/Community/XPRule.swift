import Foundation

/// What earns XP, as listed in `/meta`.
public struct XPRule: Decodable, Hashable, Sendable, Identifiable {
    public let key: String
    public let label: String
    public let xp: Int

    public var id: String { key }
}
