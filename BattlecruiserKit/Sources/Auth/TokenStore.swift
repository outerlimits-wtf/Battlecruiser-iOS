import Foundation

/// Where tokens are kept between launches.
public protocol TokenStore: Sendable {
    func load() -> Tokens?
    func save(_ tokens: Tokens?)
}

/// Tokens in memory only, for tests and previews.
public final class InMemoryTokenStore: TokenStore, @unchecked Sendable {
    private let lock = NSLock()
    private var tokens: Tokens?

    public init(_ tokens: Tokens? = nil) {
        self.tokens = tokens
    }

    public func load() -> Tokens? { lock.withLock { tokens } }
    public func save(_ tokens: Tokens?) { lock.withLock { self.tokens = tokens } }
}
