import Foundation

/// A dataset the pub's information came from, e.g. OpenStreetMap.
public struct DataSource: Decodable, Hashable, Sendable, Identifiable {
    public let key: String
    public let label: String
    public let url: String?

    public var id: String { key }
    public var linkURL: URL? { url.flatMap(URL.init(string:)) }
}
