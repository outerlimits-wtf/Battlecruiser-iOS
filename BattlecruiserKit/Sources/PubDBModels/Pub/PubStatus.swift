import Foundation

/// Whether the pub still exists. Branch on `serving` and `permanent`, never on
/// `key`, because more states will be added.
public struct PubStatus: Decodable, Hashable, Sendable {
    public let key: String
    public let label: String
    public let symbol: Symbol
    /// Can you get a drink here at all. False for anything but a trading pub.
    public let serving: Bool
    /// Is it gone for good. False for "shut for a refit".
    public let permanent: Bool
}
