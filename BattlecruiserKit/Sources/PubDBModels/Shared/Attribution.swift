import Foundation

/// Who a fact came from. Only `label` is shown; `sourceKey` is for auditing.
public struct Attribution: Decodable, Hashable, Sendable {
    /// "user", "source" or "anonymous".
    public let kind: String
    public let label: String
    public let sourceKey: String?
}
