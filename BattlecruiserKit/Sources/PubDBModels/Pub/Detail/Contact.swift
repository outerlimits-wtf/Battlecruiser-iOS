import Foundation

public struct Contact: Decodable, Hashable, Sendable {
    public let phone: String?
    public let website: String?
    public let email: String?
    public let facebook: String?
    public let instagram: String?

    public var websiteURL: URL? { website.flatMap(URL.init(string:)) }
}
