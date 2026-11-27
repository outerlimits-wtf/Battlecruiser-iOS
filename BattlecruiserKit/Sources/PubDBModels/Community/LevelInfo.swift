import Foundation

/// A level as listed in `/meta`, for explaining them.
public struct LevelInfo: Decodable, Hashable, Sendable, Identifiable {
    public let key: String
    public let name: String
    public let line: String
    public let emoji: String?
    public let minXp: Int

    public var id: String { key }
}
