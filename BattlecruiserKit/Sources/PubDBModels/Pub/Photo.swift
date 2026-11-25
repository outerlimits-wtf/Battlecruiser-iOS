import Foundation

/// Showing `attribution` and `license` beside the photo is a licence condition.
public struct Photo: Decodable, Hashable, Sendable {
    public let url: String
    public let thumbUrl: String
    public let license: String?
    public let attribution: String?
    public let descriptionUrl: String?

    public var imageURL: URL? { URL(string: url) }
    public var thumbnailURL: URL? { URL(string: thumbUrl) }
    public var descriptionURL: URL? { descriptionUrl.flatMap(URL.init(string:)) }
}
