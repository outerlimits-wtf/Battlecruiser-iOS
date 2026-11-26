import Foundation
import PubDBModels

/// Someone's profile to show, pushed onto whichever tab's stack asked.
public struct ProfileLink: Hashable, Sendable, Identifiable {
    public let username: String

    public var id: String { username }

    /// From a handle as shown ("@goatloaf") or bare.
    public init(_ handle: String) {
        username = handle.hasPrefix("@") ? String(handle.dropFirst()) : handle
    }

    /// Whoever a review or an update came from, when that is a person
    /// ("@goatloaf"); nil for a data source or someone anonymous.
    public init?(_ attribution: Attribution) {
        guard attribution.kind == "user", attribution.label.hasPrefix("@"), attribution.label.count > 1 else { return nil }
        self.init(attribution.label)
    }
}
