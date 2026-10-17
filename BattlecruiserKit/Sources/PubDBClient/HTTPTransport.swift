import Foundation

/// The one thing the client needs from the network: send a request, get bytes
/// and a response back. `URLSession` is the real one; tests supply a fake, so
/// they run offline with no shared state.
public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPTransport {
    public func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request)
    }
}
