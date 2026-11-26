import Foundation

/// Someone's level, worked out on the server from their XP (server ask S16).
/// Absent until the server sends it; the app draws nothing then.
public struct Level: Decodable, Hashable, Sendable {
    public struct Next: Decodable, Hashable, Sendable {
        public let name: String
        public let remainingLabel: String
    }

    public let key: String
    /// "Regular".
    public let name: String
    /// "They start pouring when you walk in". Only on full levels, not tags.
    public let line: String?
    public let emoji: String?
    public let xpLabel: String?
    /// Nil at the top level, and on tags.
    public let next: Next?
    /// 0–1 through the current level.
    public let progress: Double?
}
