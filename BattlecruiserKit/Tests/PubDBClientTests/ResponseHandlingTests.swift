import Foundation
import Testing
import PubDBModels
@testable import PubDBClient

/// How the client turns what comes back into models or a `PubDBError`.
struct ResponseHandlingTests {
    private let area = BoundingBox(west: -0.165, south: 51.42, east: -0.125, north: 51.45)

    @Test func aJSONListDecodes() async throws {
        let client = PubDBClient.testing(.json(#"{ "pubs": [], "count": 0 }"#))
        let list = try await client.pubs(in: area)

        #expect(list.pubs.isEmpty)
        #expect(list.count == 0)
    }

    @Test func theServersErrorBodyBecomesAServerError() async {
        let body = #"{ "error": { "code": "not_found", "message": "Unknown pub: node/1" } }"#
        let client = PubDBClient.testing(.json(body, status: 404))
        let expected = PubDBError.server(
            status: 404,
            APIErrorDetail(code: "not_found", message: "Unknown pub: node/1", field: nil)
        )

        await #expect(throws: expected) {
            try await client.pub(id: "node/1")
        }
    }

    @Test func htmlInsteadOfJSONIsUnexpectedContentEvenWithA200() async {
        // Unknown paths fall through to the web app's page with a 200.
        let transport = FakeTransport(.response(status: 200, contentType: "text/html;charset=utf-8", body: "<!doctype html>"))
        let client = PubDBClient.testing(transport)

        await #expect(throws: PubDBError.unexpectedContent(status: 200, contentType: "text/html;charset=utf-8")) {
            try await client.pubs(in: area)
        }
    }

    @Test func aFailureStatusWithoutAnErrorBodyIsAnHTTPError() async {
        let transport = FakeTransport(.response(status: 502, contentType: "text/html", body: "Bad gateway"))
        let client = PubDBClient.testing(transport)

        await #expect(throws: PubDBError.http(status: 502)) {
            try await client.pubs(in: area)
        }
    }

    @Test func jsonTheModelsCannotReadIsADecodingError() async {
        let client = PubDBClient.testing(.json(#"{ "pubs": "not a list" }"#))

        let error = await #expect(throws: PubDBError.self) {
            try await client.pubs(in: area)
        }
        guard case .decoding = error else {
            Issue.record("Expected a decoding error, got \(String(describing: error))")
            return
        }
    }

    @Test func noConnectionIsATransportErrorThatReadsAsOffline() async {
        let offline = URLError(.notConnectedToInternet)
        let client = PubDBClient.testing(FakeTransport(.failure(offline)))

        let error = await #expect(throws: PubDBError.self) {
            try await client.pubs(in: area)
        }
        #expect(error == .transport(offline))
        #expect(error?.isOffline == true)
        #expect(error?.userMessage.contains("offline") == true)
    }

    @Test func aCancelledRequestThrowsCancellationNotAnError() async {
        let client = PubDBClient.testing(FakeTransport(.failure(URLError(.cancelled))))

        await #expect(throws: CancellationError.self) {
            try await client.pubs(in: area)
        }
    }

    @Test func theServersMessageIsWhatTheUserSees() {
        let detail = APIErrorDetail(code: "rate_limited", message: "Slow down a bit.", field: nil)
        let error = PubDBError.server(status: 429, detail)

        #expect(error.userMessage == "Slow down a bit.")
        #expect(!error.isOffline)
    }
}
