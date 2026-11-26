import Foundation

/// What a contribution, review or report came to. The server's own row comes
/// back too, unpresented, so the app reloads the pub to show it (S12 asks for
/// the presented row instead).
public struct WriteResult: Decodable, Hashable, Sendable {
    /// True when the change waits for an admin (`202`): show `message`, don't reload.
    public let queued: Bool
    /// The server's words, when it has some to say.
    public let message: String?

    private enum CodingKeys: String, CodingKey {
        case queued, message
    }

    public init(queued: Bool = false, message: String? = nil) {
        self.queued = queued
        self.message = message
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        queued = try container.decodeIfPresent(Bool.self, forKey: .queued) ?? false
        message = try container.decodeIfPresent(String.self, forKey: .message)
    }
}
