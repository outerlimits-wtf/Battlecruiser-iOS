import Foundation

/// A response as it came from the server, and when.
public struct CachedResponse: Equatable, Sendable {
    /// The raw response body, exactly as received, so it decodes the same way
    /// a fresh one does.
    public let data: Data
    /// When the server sent it. Open states in it are true only for this moment.
    public let fetchedAt: Date

    public init(data: Data, fetchedAt: Date) {
        self.data = data
        self.fetchedAt = fetchedAt
    }
}
