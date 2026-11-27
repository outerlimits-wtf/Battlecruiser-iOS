import Foundation

/// What a contribution, review or report came to. A `201` from a contribution
/// or review also carries the whole pub as it now stands (S12), so the app
/// shows that rather than fetching it again.
public struct WriteResult: Decodable, Hashable, Sendable {
    /// True when the change waits for an admin (`202`): show `message`, don't reload.
    public let queued: Bool
    /// The server's words, when it has some to say.
    public let message: String?
    /// The pub after the write, as `GET /pubs/{id}` would send it. Nil for a
    /// `202`, a removal or a report, and if it fails to decode: the write still
    /// happened, so the app falls back to fetching the pub.
    public let pub: PubDetail?

    private enum CodingKeys: String, CodingKey {
        case queued, message, pub
    }

    public init(queued: Bool = false, message: String? = nil, pub: PubDetail? = nil) {
        self.queued = queued
        self.message = message
        self.pub = pub
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        queued = try container.decodeIfPresent(Bool.self, forKey: .queued) ?? false
        message = try container.decodeIfPresent(String.self, forKey: .message)
        pub = (try? container.decodeIfPresent(PubDetail.self, forKey: .pub)) ?? nil
    }
}
