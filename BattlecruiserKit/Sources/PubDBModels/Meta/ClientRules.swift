import Foundation

/// Per-platform rules. Today only the oldest iOS build allowed to run.
public struct ClientRules: Decodable, Hashable, Sendable {
    public struct Platform: Decodable, Hashable, Sendable {
        /// Below this, the app shows "update the app" and nothing else. Nil: no floor.
        public let minVersion: String?
    }

    public let ios: Platform
}
