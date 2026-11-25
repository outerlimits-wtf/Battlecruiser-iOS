import Foundation

/// A pub's listing, when it has one (that is what `listed` means).
public struct Heritage: Decodable, Hashable, Sendable {
    /// "Grade II listed building".
    public let designation: String?
    public let inception: String?
    public let wikipediaUrl: String?

    public var wikipediaURL: URL? { wikipediaUrl.flatMap(URL.init(string:)) }
}
