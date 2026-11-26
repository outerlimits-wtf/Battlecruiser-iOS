import Foundation

/// `GET /watchlist` and `GET /visited`: the person's pubs, newest first, with
/// coverage on the visited list.
public struct SavedPubs: Decodable, Hashable, Sendable {
    public let pubs: [PubSummary]
    public let coverage: Coverage?

    private enum CodingKeys: String, CodingKey {
        case pubs, coverage
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pubs = try LossyArray.decode(PubSummary.self, from: container, forKey: .pubs)
        coverage = try? container.decodeIfPresent(Coverage.self, forKey: .coverage)
    }
}
