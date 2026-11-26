import Foundation

/// A pub to open on the map, from anywhere in the app.
public struct PubLink: Hashable, Sendable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
