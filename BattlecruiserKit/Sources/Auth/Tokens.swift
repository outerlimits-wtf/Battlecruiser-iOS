import Foundation

/// What WorkOS hands back: a short-lived access token for PubDB, and a
/// refresh token for getting the next one.
public struct Tokens: Codable, Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }

    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
