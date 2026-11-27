import Foundation

/// Where a tapped push goes, as the inbox row with the same type would.
public struct PushRoute: Equatable, Sendable {
    public let type: String
    public let username: String?
    public let pubID: String?
}
