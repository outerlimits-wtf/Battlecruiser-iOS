import Foundation
import PubDBClient

/// Swaps a sign-in code, or a refresh token, for tokens, directly with WorkOS
/// (`POST /user_management/authenticate`). PubDB is not involved.
struct WorkOSTokenEndpoint: Sendable {
    let configuration: AuthConfiguration
    let transport: any HTTPTransport

    func exchange(code: String, verifier: String) async throws -> Tokens {
        try await authenticate([
            "client_id": configuration.clientID,
            "grant_type": "authorization_code",
            "code": code,
            "code_verifier": verifier,
        ])
    }

    func refresh(_ refreshToken: String) async throws -> Tokens {
        try await authenticate([
            "client_id": configuration.clientID,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
        ])
    }

    private func authenticate(_ body: [String: String]) async throws -> Tokens {
        var request = URLRequest(url: configuration.apiBase.appending(path: "user_management/authenticate"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await transport.send(request)
        } catch {
            throw AuthError.unavailable
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if (400..<500).contains(status) {
            let reason = (try? JSONDecoder().decode([String: String].self, from: data))?["error_description"]
            throw AuthError.refused(reason ?? "the sign-in was refused")
        }
        guard (200..<300).contains(status), let tokens = try? JSONDecoder().decode(Tokens.self, from: data) else {
            throw AuthError.unavailable
        }
        return tokens
    }
}
