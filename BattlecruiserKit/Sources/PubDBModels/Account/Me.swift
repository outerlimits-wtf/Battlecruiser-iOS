import Foundation

/// `GET /me`: whether this server has sign-in at all, and who is signed in.
public struct Me: Decodable, Hashable, Sendable {
    /// False when the server runs without sign-in (a dev server): then show
    /// no sign-in anywhere.
    public let authRequired: Bool
    /// Nil when signed out.
    public let user: MeUser?
    /// Why nobody is signed in. Diagnostics only: draw nothing from it,
    /// except that "invalid-bearer" means the token needs refreshing.
    public let session: SessionDiagnostics?

    public struct SessionDiagnostics: Decodable, Hashable, Sendable {
        public let why: String?
    }

    public init(authRequired: Bool, user: MeUser?, session: SessionDiagnostics?) {
        self.authRequired = authRequired
        self.user = user
        self.session = session
    }

    public var isInvalidBearer: Bool {
        user == nil && session?.why == "invalid-bearer"
    }
}

/// The signed-in person.
public struct MeUser: Decodable, Hashable, Sendable {
    public let id: String
    /// The bare handle, for editing ("goatloaf").
    public let username: String
    /// How to show it ("@goatloaf").
    public let label: String
    /// False while the server's made-up handle stands: invite them to pick one.
    public let usernameChosen: Bool
    public let contributions: Int
    /// Decides only whether to show operator links.
    public let admin: Bool
    public let avatarUrl: String?
    public let visited: Int?
    public let reviews: Int?
    /// Their level (S16); nil until the server sends it.
    public let level: Level?

    public var avatarURL: URL? { avatarUrl.flatMap(URL.init(string:)) }
}
