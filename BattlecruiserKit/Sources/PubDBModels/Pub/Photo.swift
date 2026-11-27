import Foundation

/// Showing `attribution` and `license` beside the photo is a licence condition.
public struct Photo: Decodable, Hashable, Sendable {
    public let url: String
    public let thumbUrl: String
    public let license: String?
    public let attribution: String?
    public let descriptionUrl: String?
    /// Set on photos people uploaded: what it shows ("pint", "front"…) and
    /// what they said about it.
    public let kind: String?
    public let caption: String?
    /// Uploaded photos have an id, for reporting; scraped ones don't.
    public let id: String?

    private enum CodingKeys: String, CodingKey {
        case url, thumbUrl, license, attribution, descriptionUrl, kind, caption, id
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(String.self, forKey: .url)
        thumbUrl = try container.decode(String.self, forKey: .thumbUrl)
        license = try container.decodeIfPresent(String.self, forKey: .license)
        attribution = try container.decodeIfPresent(String.self, forKey: .attribution)
        descriptionUrl = try container.decodeIfPresent(String.self, forKey: .descriptionUrl)
        kind = try container.decodeIfPresent(String.self, forKey: .kind)
        caption = try container.decodeIfPresent(String.self, forKey: .caption)
        // A number or a string, depending on where it came from.
        if let number = try? container.decodeIfPresent(Int.self, forKey: .id) {
            id = String(number)
        } else {
            id = try? container.decodeIfPresent(String.self, forKey: .id)
        }
    }

    public var imageURL: URL? { URL(string: url) }
    public var thumbnailURL: URL? { URL(string: thumbUrl) }
    public var descriptionURL: URL? { descriptionUrl.flatMap(URL.init(string:)) }
}
