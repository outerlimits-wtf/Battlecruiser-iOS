import Foundation
import PubDBClient
import PubDBModels
@testable import PubsFeature

/// Answers fetches from a script and records what it was asked for.
final class FakePubSource: PubSource, @unchecked Sendable {
    struct Request: Equatable {
        let area: BoundingBox
        let location: Coordinate?
    }

    private let lock = NSLock()
    private var recorded: [Request] = []
    private var respond: (BoundingBox) throws -> PubList
    private var saved: Cached<PubList>?

    init(respond: @escaping (BoundingBox) throws -> PubList = { _ in PubFixtures.list([]) }) {
        self.respond = respond
    }

    var requests: [Request] {
        lock.withLock { recorded }
    }

    /// What `cachedPubs()` returns: the list "saved on disk".
    func setCached(_ cached: Cached<PubList>?) {
        lock.withLock { saved = cached }
    }

    func cachedPubs() async -> Cached<PubList>? {
        lock.withLock { saved }
    }

    /// Change what the next fetches return.
    func script(_ respond: @escaping (BoundingBox) throws -> PubList) {
        lock.withLock { self.respond = respond }
    }

    /// A search with no area is recorded with this one, so tests can still compare areas.
    static let noArea = BoundingBox(west: 0, south: 0, east: 0, north: 0)

    func fetchPubs(matching query: PubQuery, in area: BoundingBox?, near location: Coordinate?) async throws -> PubList {
        let area = area ?? Self.noArea
        let respond = lock.withLock {
            recorded.append(Request(area: area, location: location))
            queries.append(query)
            return self.respond
        }
        return try respond(area)
    }

    private var queries: [PubQuery] = []

    var receivedQueries: [PubQuery] {
        lock.withLock { queries }
    }
}
