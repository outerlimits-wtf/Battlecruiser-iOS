import Foundation
import PubDBClient

/// The signed-in person's tokens: got by signing in, kept in the Keychain,
/// refreshed with WorkOS when PubDB refuses them. The one place auth lives
/// (decision D19); the client asks it for tokens through `TokenProvider`.
public actor AuthSession: TokenProvider {
    private let configuration: AuthConfiguration?
    private let endpoint: WorkOSTokenEndpoint?
    private let store: any TokenStore
    private var tokens: Tokens?
    private var pending: SignInAttempt?
    /// A refresh under way, shared by every request that hit a 401 meanwhile.
    private var refreshing: Task<Result<Tokens, AuthError>, Never>?

    public init(
        configuration: AuthConfiguration?,
        store: any TokenStore = KeychainTokenStore(),
        transport: any HTTPTransport = URLSession.shared
    ) {
        self.configuration = configuration
        endpoint = configuration.map { WorkOSTokenEndpoint(configuration: $0, transport: transport) }
        self.store = store
        tokens = store.load()
    }

    /// The app's session: the client id from Info.plist, tokens in the Keychain.
    public static func live() -> AuthSession {
        AuthSession(configuration: .fromBundle())
    }

    /// Whether this build can sign in at all.
    public nonisolated var isConfigured: Bool { configuration != nil }

    public var isSignedIn: Bool { tokens != nil }

    // MARK: - Signing in and out

    /// Start signing in: open the returned attempt's URL in the system sheet.
    public func beginSignIn() throws -> SignInAttempt {
        guard let configuration else { throw AuthError.notConfigured }
        let attempt = SignInAttempt.make(configuration)
        pending = attempt
        return attempt
    }

    /// Finish with the URL the sheet was redirected to.
    public func finishSignIn(callback: URL) async throws {
        guard let attempt = pending, let endpoint else { throw AuthError.notConfigured }
        pending = nil
        let code = try attempt.code(from: callback)
        let fresh = try await endpoint.exchange(code: code, verifier: attempt.pkce.verifier)
        keep(fresh)
    }

    /// Forget the tokens. The server has nothing to revoke; an access token
    /// already issued lapses within minutes (spec, "Native clients").
    public func signOut() {
        refreshing?.cancel()
        refreshing = nil
        keep(nil)
    }

    // MARK: - TokenProvider

    public func accessToken() async -> String? {
        tokens?.accessToken
    }

    public func refreshedAccessToken() async -> String? {
        let task: Task<Result<Tokens, AuthError>, Never>
        if let refreshing {
            task = refreshing
        } else {
            guard let endpoint, let refreshToken = tokens?.refreshToken else { return nil }
            task = Task {
                do { return .success(try await endpoint.refresh(refreshToken)) }
                catch let error as AuthError { return .failure(error) }
                catch { return .failure(.unavailable) }
            }
            refreshing = task
        }
        let result = await task.value
        if refreshing == task { refreshing = nil }
        switch result {
        case .success(let fresh):
            keep(fresh)
            return fresh.accessToken
        case .failure(.unavailable):
            // No signal is not a refusal: keep the tokens and try again later.
            return nil
        case .failure:
            // WorkOS refused the refresh token: the person is signed out.
            keep(nil)
            return nil
        }
    }

    private func keep(_ fresh: Tokens?) {
        tokens = fresh
        store.save(fresh)
    }
}
