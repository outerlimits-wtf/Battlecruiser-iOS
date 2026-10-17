import Foundation
import PubDBClient
import PubDBModels
@testable import PubDetailFeature

/// Answers detail fetches from a script and records what it was asked for.
final class FakeDetailSource: PubDetailSource, @unchecked Sendable {
    struct Request: Equatable {
        let id: String
        let location: Coordinate?
    }

    private let lock = NSLock()
    private var recorded: [Request] = []
    private var respond: (String) throws -> PubDetail

    init(respond: @escaping (String) throws -> PubDetail = { DetailFixtures.detail(id: $0) }) {
        self.respond = respond
    }

    var requests: [Request] {
        lock.withLock { recorded }
    }

    /// Change what the next fetches return.
    func script(_ respond: @escaping (String) throws -> PubDetail) {
        lock.withLock { self.respond = respond }
    }

    func fetchPub(id: String, near location: Coordinate?) async throws -> PubDetail {
        let respond = lock.withLock {
            recorded.append(Request(id: id, location: location))
            return self.respond
        }
        return try respond(id)
    }
}
