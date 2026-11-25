import Foundation
import Testing
@testable import PubDBClient

/// Bearer tokens (spec, "Native clients"): sent on every request; on a 401,
/// refresh once and retry once.
struct BearerTests {
    private final class FakeTokens: TokenProvider, @unchecked Sendable {
        var current: String?
        var refreshed: String?
        private(set) var refreshes = 0

        init(current: String?, refreshed: String?) {
            self.current = current
            self.refreshed = refreshed
        }

        func accessToken() async -> String? { current }

        func refreshedAccessToken() async -> String? {
            refreshes += 1
            current = refreshed
            return refreshed
        }
    }

    private struct Body: Decodable { let ok: Bool }

    private static let unauthorised = ScriptedTransport.Reply(
        status: 401,
        body: #"{ "error": { "code": "not_authenticated", "message": "Sign in first." } }"#,
        headers: ["Content-Type": "application/json"]
    )
    private static let fine = ScriptedTransport.Reply(status: 200, body: #"{ "ok": true }"#, headers: ["Content-Type": "application/json"])

    private func client(_ transport: ScriptedTransport, _ tokens: FakeTokens?) -> PubDBClient {
        PubDBClient(baseURL: URL(string: "https://pubdb.test/api/v1")!, transport: transport, now: { .now }, tokens: tokens)
    }

    @Test func theTokenGoesOnEveryRequest() async throws {
        let transport = ScriptedTransport([Self.fine])
        let _: Body = try await client(transport, FakeTokens(current: "abc", refreshed: nil)).send(Endpoint(path: ["meta"]))

        #expect(transport.requests[0].value(forHTTPHeaderField: "Authorization") == "Bearer abc")
    }

    @Test func signedOutSendsNoHeader() async throws {
        let transport = ScriptedTransport([Self.fine])
        let _: Body = try await client(transport, nil).send(Endpoint(path: ["meta"]))

        #expect(transport.requests[0].value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test func a401RefreshesOnceAndRetriesWithTheNewToken() async throws {
        let transport = ScriptedTransport([Self.unauthorised, Self.fine])
        let tokens = FakeTokens(current: "old", refreshed: "new")

        let body: Body = try await client(transport, tokens).send(Endpoint(path: ["me"]))

        #expect(body.ok)
        #expect(tokens.refreshes == 1)
        #expect(transport.requests.map { $0.value(forHTTPHeaderField: "Authorization") } == ["Bearer old", "Bearer new"])
    }

    @Test func aSecond401IsTheErrorNotAnotherRetry() async {
        let transport = ScriptedTransport([Self.unauthorised, Self.unauthorised])
        let tokens = FakeTokens(current: "old", refreshed: "new")

        await #expect(throws: PubDBError.self) {
            let _: Body = try await client(transport, tokens).send(Endpoint(path: ["me"]))
        }
        #expect(tokens.refreshes == 1)
        #expect(transport.requests.count == 2)
    }

    @Test func aFailedRefreshDoesNotRetry() async {
        let transport = ScriptedTransport([Self.unauthorised])
        let tokens = FakeTokens(current: "old", refreshed: nil)

        await #expect(throws: PubDBError.self) {
            let _: Body = try await client(transport, tokens).send(Endpoint(path: ["me"]))
        }
        #expect(transport.requests.count == 1)
    }
}
