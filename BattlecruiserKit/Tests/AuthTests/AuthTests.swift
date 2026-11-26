import Foundation
import Testing
import PubDBClient
@testable import Auth

struct PKCETests {
    /// RFC 7636, appendix B.
    @Test func theChallengeIsTheVerifiersSHA256InBase64URL() {
        let pkce = PKCE(verifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
        #expect(pkce.challenge == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }

    @Test func verifiersAreFreshAndURLSafe() {
        let a = PKCE.make().verifier
        let b = PKCE.make().verifier
        #expect(a != b)
        #expect(a.count >= 43)
        #expect(a.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" })
    }
}

struct SignInAttemptTests {
    private let configuration = AuthConfiguration(clientID: "client_test")

    @Test func theAuthorizeURLAsksForACodeWithPKCE() throws {
        let attempt = SignInAttempt.make(configuration, pkce: PKCE(verifier: "v"), state: "s1")
        let items = Dictionary(uniqueKeysWithValues: (URLComponents(url: attempt.url, resolvingAgainstBaseURL: false)?.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(attempt.url.path == "/user_management/authorize")
        #expect(items["client_id"] == "client_test")
        #expect(items["redirect_uri"] == "wtf.outerlimits.battlecruiser:/auth/callback")
        #expect(items["response_type"] == "code")
        #expect(items["code_challenge_method"] == "S256")
        #expect(items["code_challenge"] == PKCE(verifier: "v").challenge)
        #expect(items["state"] == "s1")
        #expect(attempt.callbackScheme == "wtf.outerlimits.battlecruiser")
    }

    @Test func theCodeComesBackOnlyWithTheRightState() throws {
        let attempt = SignInAttempt.make(configuration, state: "s1")

        #expect(try attempt.code(from: URL(string: "wtf.outerlimits.battlecruiser:/auth/callback?code=abc&state=s1")!) == "abc")
        #expect(throws: AuthError.stateMismatch) {
            try attempt.code(from: URL(string: "wtf.outerlimits.battlecruiser:/auth/callback?code=abc&state=other")!)
        }
        #expect(throws: AuthError.refused("Nope")) {
            try attempt.code(from: URL(string: "wtf.outerlimits.battlecruiser:/auth/callback?error=access_denied&error_description=Nope")!)
        }
    }
}

struct AuthSessionTests {
    private final class WorkOS: HTTPTransport, @unchecked Sendable {
        private let lock = NSLock()
        var replies: [(Int, String)]
        private(set) var bodies: [[String: String]] = []

        init(_ replies: [(Int, String)]) { self.replies = replies }

        func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
            let (status, body) = lock.withLock {
                bodies.append((try? JSONDecoder().decode([String: String].self, from: request.httpBody ?? Data())) ?? [:])
                return replies.removeFirst()
            }
            if status == 0 { throw URLError(.notConnectedToInternet) }
            return (Data(body.utf8), HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!)
        }
    }

    private static let tokens = #"{ "access_token": "a2", "refresh_token": "r2", "user": {} }"#

    @Test func signingInSwapsTheCodeAndVerifierForTokensAndKeepsThem() async throws {
        let workOS = WorkOS([(200, Self.tokens)])
        let store = InMemoryTokenStore()
        let session = AuthSession(configuration: AuthConfiguration(clientID: "c"), store: store, transport: workOS)

        let attempt = try await session.beginSignIn()
        try await session.finishSignIn(callback: URL(string: "wtf.outerlimits.battlecruiser:/auth/callback?code=xyz&state=\(attempt.state)")!)

        #expect(await session.accessToken() == "a2")
        #expect(store.load() == Tokens(accessToken: "a2", refreshToken: "r2"))
        #expect(workOS.bodies.first?["grant_type"] == "authorization_code")
        #expect(workOS.bodies.first?["code_verifier"] == attempt.pkce.verifier)
    }

    @Test func aRefreshReplacesTheTokens() async {
        let workOS = WorkOS([(200, Self.tokens)])
        let session = AuthSession(configuration: AuthConfiguration(clientID: "c"), store: InMemoryTokenStore(Tokens(accessToken: "a1", refreshToken: "r1")), transport: workOS)

        #expect(await session.refreshedAccessToken() == "a2")
        #expect(workOS.bodies.first?["refresh_token"] == "r1")
    }

    @Test func aRefusedRefreshSignsOutButNoSignalDoesNot() async {
        let offline = AuthSession(configuration: AuthConfiguration(clientID: "c"), store: InMemoryTokenStore(Tokens(accessToken: "a1", refreshToken: "r1")), transport: WorkOS([(0, "")]))
        #expect(await offline.refreshedAccessToken() == nil)
        #expect(await offline.isSignedIn)

        let refused = AuthSession(configuration: AuthConfiguration(clientID: "c"), store: InMemoryTokenStore(Tokens(accessToken: "a1", refreshToken: "r1")), transport: WorkOS([(400, #"{ "error": "invalid_grant" }"#)]))
        #expect(await refused.refreshedAccessToken() == nil)
        #expect(await !refused.isSignedIn)
    }

    @Test func withoutAClientIDThereIsNoSignIn() async {
        let session = AuthSession(configuration: nil, store: InMemoryTokenStore())
        #expect(!session.isConfigured)
        await #expect(throws: AuthError.notConfigured) { try await session.beginSignIn() }
    }
}
