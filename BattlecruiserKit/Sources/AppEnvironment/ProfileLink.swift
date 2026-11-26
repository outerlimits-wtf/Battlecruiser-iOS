import Foundation

/// Someone's profile to show, pushed onto whichever tab's stack asked.
public struct ProfileLink: Hashable, Sendable {
    public let username: String

    /// From a handle as shown ("@goatloaf") or bare.
    public init(_ handle: String) {
        username = handle.hasPrefix("@") ? String(handle.dropFirst()) : handle
    }
}
