import Foundation

/// `GET /feed`. Lossy: an entry that can't be read is skipped.
public struct Feed: Decodable, Hashable, Sendable {
    public let updates: [FeedEntry]

    private enum CodingKeys: String, CodingKey {
        case updates
    }

    public init(from decoder: any Decoder) throws {
        updates = try LossyArray.decode(FeedEntry.self, from: decoder.container(keyedBy: CodingKeys.self), forKey: .updates)
    }
}
