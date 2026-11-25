import Foundation
import Auth

/// Signing in and out. `AuthSession` in the app; a fake in tests.
public protocol Authenticator: Sendable {
    nonisolated var isConfigured: Bool { get }
    func beginSignIn() async throws -> SignInAttempt
    func finishSignIn(callback: URL) async throws
    func signOut() async
    func refreshedAccessToken() async -> String?
}

extension AuthSession: Authenticator {}
