import Foundation

/// One sign-in in progress: the page to open, and what's needed to finish.
public struct SignInAttempt: Sendable, Equatable {
    /// Open this in the system sign-in sheet.
    public let url: URL
    /// Listen for redirects to this scheme.
    public let callbackScheme: String
    let state: String
    let pkce: PKCE

    static func make(_ configuration: AuthConfiguration, pkce: PKCE = .make(), state: String = UUID().uuidString) -> SignInAttempt {
        var components = URLComponents(url: configuration.apiBase.appending(path: "user_management/authorize"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI.absoluteString),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "provider", value: "authkit"),
            URLQueryItem(name: "code_challenge", value: pkce.challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state),
        ]
        return SignInAttempt(url: components.url!, callbackScheme: configuration.callbackScheme, state: state, pkce: pkce)
    }

    /// The code from the redirect, if it is this attempt's.
    func code(from callback: URL) throws -> String {
        let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let value = { (name: String) in items.first { $0.name == name }?.value }
        if let error = value("error") {
            throw AuthError.refused(value("error_description") ?? error)
        }
        guard value("state") == state else { throw AuthError.stateMismatch }
        guard let code = value("code"), !code.isEmpty else { throw AuthError.noCode }
        return code
    }
}
