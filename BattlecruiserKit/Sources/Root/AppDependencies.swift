import Foundation
import Auth
import PubDBClient

/// Everything the app talks to, made once at launch and handed to the root.
/// Tests and previews make their own.
public struct AppDependencies: Sendable {
    public var client: PubDBClient
    public var auth: AuthSession

    public init(client: PubDBClient, auth: AuthSession) {
        self.client = client
        self.auth = auth
    }

    /// The real server, with the app's response cache, signed in through
    /// WorkOS when a client id is given.
    public static func live(workOSClientID: String?) -> AppDependencies {
        let configuration = workOSClientID.flatMap { $0.isEmpty ? nil : AuthConfiguration(clientID: $0) }
        let auth = AuthSession(configuration: configuration)
        return AppDependencies(client: .live(tokens: auth), auth: auth)
    }

    /// Production without a disk cache or sign-in, for previews.
    public static let preview = AppDependencies(
        client: PubDBClient(),
        auth: AuthSession(configuration: nil, store: InMemoryTokenStore())
    )
}
