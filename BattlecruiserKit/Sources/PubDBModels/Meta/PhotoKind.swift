import Foundation

/// What an uploaded photo shows: pint, front, garden… In the order to offer them.
public struct PhotoKind: Decodable, Hashable, Sendable, Identifiable {
    public let key: String
    public let label: String

    public var id: String { key }
}
