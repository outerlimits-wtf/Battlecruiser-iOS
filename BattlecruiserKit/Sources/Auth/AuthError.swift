import Foundation

/// What can go wrong signing in.
public enum AuthError: Error, Equatable, Sendable {
    /// No WorkOS client id in this build.
    case notConfigured
    /// The person cancelled the sign-in sheet.
    case cancelled
    /// WorkOS said no, with its reason.
    case refused(String)
    /// The redirect wasn't for the sign-in this app started.
    case stateMismatch
    case noCode
    /// WorkOS couldn't be reached or answered unexpectedly.
    case unavailable

    /// A line for the person; nil for a cancel, which needs none.
    public var userMessage: String? {
        switch self {
        case .cancelled: nil
        case .notConfigured: "Signing in isn't set up in this build."
        case .refused(let reason): "Sign-in failed: \(reason)"
        case .stateMismatch, .noCode, .unavailable: "Sign-in failed. Try again in a moment."
        }
    }
}
