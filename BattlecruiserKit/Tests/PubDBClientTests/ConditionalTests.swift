import Foundation
import Testing
@testable import PubDBClient

/// `If-None-Match` and `304`, as `/pins` needs them (spec, "Building a map").
struct ConditionalTests {
    private struct Body: Decodable, Equatable, Sendable {
        let n: Int
    }

    private let json = ["Content-Type": "application/geo+json"]

    @Test func aTagIsSentBackAndA304ReadsAsUnchanged() async throws {
        let transport = ScriptedTransport([
            .init(status: 200, body: #"{ "n": 1 }"#, headers: json.merging(["ETag": #"W/"abc""#]) { $1 }),
            .init(status: 304),
        ])
        let client = Self.client(transport)
        let endpoint = Endpoint(path: ["pins"], query: [URLQueryItem(name: "amenity", value: "pub")])

        let first: Conditional<Body> = try await client.sendConditional(endpoint)
        let second: Conditional<Body> = try await client.sendConditional(endpoint)

        #expect(first == .changed(Body(n: 1)))
        #expect(second == .unchanged)
        #expect(transport.requests[0].value(forHTTPHeaderField: "If-None-Match") == nil)
        #expect(transport.requests[1].value(forHTTPHeaderField: "If-None-Match") == #"W/"abc""#)
    }

    @Test func tagsAreKeptPerFilterSetIgnoringOrderAndTheClock() {
        let a = Endpoint(path: ["pins"], query: [.init(name: "amenity", value: "pub"), .init(name: "openNow", value: "1")])
        let b = Endpoint(path: ["pins"], query: [.init(name: "openNow", value: "1"), .init(name: "amenity", value: "pub"), .init(name: "at", value: "x")])
        let c = Endpoint(path: ["pins"], query: [.init(name: "amenity", value: "bar")])

        #expect(a.etagKey == b.etagKey)
        #expect(a.etagKey != c.etagKey)
    }

    @Test func aBodyThatFailsToDecodeLeavesNoTag() async throws {
        let transport = ScriptedTransport([
            .init(status: 200, body: #"{ "n": "one" }"#, headers: json.merging(["ETag": "t1"]) { $1 }),
            .init(status: 200, body: #"{ "n": 2 }"#, headers: json),
        ])
        let client = Self.client(transport)
        let endpoint = Endpoint(path: ["pins"])

        let _: Conditional<Body>? = try? await client.sendConditional(endpoint)
        let second: Conditional<Body> = try await client.sendConditional(endpoint)

        #expect(transport.requests[1].value(forHTTPHeaderField: "If-None-Match") == nil)
        #expect(second == .changed(Body(n: 2)))
    }

    private static func client(_ transport: ScriptedTransport) -> PubDBClient {
        PubDBClient(baseURL: URL(string: "https://pubdb.test/api/v1")!, transport: transport, now: { .now })
    }
}
