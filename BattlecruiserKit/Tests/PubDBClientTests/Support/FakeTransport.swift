import Foundation
@testable import PubDBClient

/// Answers every request with one scripted response and remembers the requests
/// it was sent. Each test makes its own, so tests can run in parallel safely.
final class FakeTransport: HTTPTransport, @unchecked Sendable {
    enum Reply {
        case response(status: Int, contentType: String?, body: String)
        case failure(any Error)
    }

    private let reply: Reply
    private let lock = NSLock()
    private var recorded: [URLRequest] = []

    init(_ reply: Reply) {
        self.reply = reply
    }

    /// A 200 JSON response, the common case.
    static func json(_ body: String, status: Int = 200) -> FakeTransport {
        FakeTransport(.response(status: status, contentType: "application/json;charset=utf-8", body: body))
    }

    var requests: [URLRequest] {
        lock.withLock { recorded }
    }

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        lock.withLock { recorded.append(request) }
        switch reply {
        case .failure(let error):
            throw error
        case .response(let status, let contentType, let body):
            let headers = contentType.map { ["Content-Type": $0] } ?? [:]
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers)!
            return (Data(body.utf8), response)
        }
    }
}

extension PubDBClient {
    /// A client against a fake host with a fixed clock, so request URLs are exact.
    static func testing(_ transport: FakeTransport) -> PubDBClient {
        PubDBClient(
            baseURL: URL(string: "https://pubdb.test/api/v1")!,
            transport: transport,
            now: { Date(timeIntervalSince1970: 1_760_560_200) } // 2025-10-15T20:30:00Z
        )
    }
}
