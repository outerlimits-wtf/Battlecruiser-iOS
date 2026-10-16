import Foundation

/// The body of `GET /pubs` and `GET /pubs/{id}/similar`.
///
/// Decoding is lossy on purpose: a pub that fails to decode is skipped and
/// counted rather than failing the whole response, so one odd record never
/// blanks the map. Tests assert `droppedCount` is zero for real payloads.
public struct PubList: Decodable, Hashable, Sendable {
    public let pubs: [PubSummary]
    /// Sent by `GET /pubs`; absent from `similar`.
    public let count: Int?
    /// Pubs in the response that could not be decoded. Not part of the JSON.
    public let droppedCount: Int

    private enum CodingKeys: String, CodingKey {
        case pubs, count
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        count = try container.decodeIfPresent(Int.self, forKey: .count)

        var elements = try container.nestedUnkeyedContainer(forKey: .pubs)
        var pubs: [PubSummary] = []
        var dropped = 0
        while !elements.isAtEnd {
            do {
                pubs.append(try elements.decode(PubSummary.self))
            } catch {
                // A failed decode does not advance the container; consume the
                // element with a type that always succeeds, then move on.
                _ = try elements.decode(SkippedElement.self)
                dropped += 1
            }
        }
        self.pubs = pubs
        droppedCount = dropped
    }
}

/// Decodes any JSON value without reading it, to step past a bad array element.
private struct SkippedElement: Decodable {
    init(from decoder: any Decoder) throws {}
}
