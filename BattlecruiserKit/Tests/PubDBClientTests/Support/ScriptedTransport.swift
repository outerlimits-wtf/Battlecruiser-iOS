import Foundation
@testable import PubDBClient

/// Answers requests in turn from a script, so a test can see a `200` and then
/// a `304`. Remembers what it was sent.
final class ScriptedTransport: HTTPTransport, @unchecked Sendable {
    struct Reply {
        var status: Int
        var body: String = ""
        var headers: [String: String] = [:]
    }

    private let lock = NSLock()
    private var script: [Reply]
    private var recorded: [URLRequest] = []

    init(_ script: [Reply]) {
        self.script = script
    }

    var requests: [URLRequest] {
        lock.withLock { recorded }
    }

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let reply = lock.withLock {
            recorded.append(request)
            return script.removeFirst()
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: reply.status, httpVersion: "HTTP/1.1", headerFields: reply.headers)!
        return (Data(reply.body.utf8), response)
    }
}
