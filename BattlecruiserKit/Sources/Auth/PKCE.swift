import CryptoKit
import Foundation

/// Proof Key for Code Exchange (RFC 7636): a secret made on the device for each
/// sign-in, so the code coming back is useless to anyone else.
struct PKCE: Sendable, Equatable {
    let verifier: String

    /// A fresh 256-bit verifier.
    static func make() -> PKCE {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return PKCE(verifier: Data(bytes).base64URLEncoded())
    }

    /// `S256`: the verifier's SHA-256, base64url without padding.
    var challenge: String {
        Data(SHA256.hash(data: Data(verifier.utf8))).base64URLEncoded()
    }
}

extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
