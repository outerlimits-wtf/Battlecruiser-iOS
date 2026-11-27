import Foundation

/// `GET /pins`: every pub matching the filters, as a GeoJSON `FeatureCollection`,
/// quietest first (so drawing in order puts open pubs on top).
///
/// Lossy like `PubList`: a feature that fails to decode is skipped and counted,
/// so one odd record never blanks the map.
public struct PinCollection: Decodable, Hashable, Sendable {
    public let pins: [Pin]
    /// Features in the response that could not be decoded. Not part of the JSON.
    public let droppedCount: Int

    public init(pins: [Pin]) {
        self.pins = pins
        droppedCount = 0
    }

    private enum CodingKeys: String, CodingKey {
        case features
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var elements = try container.nestedUnkeyedContainer(forKey: .features)
        var pins: [Pin] = []
        var dropped = 0
        while !elements.isAtEnd {
            do {
                pins.append(try elements.decode(Pin.self))
            } catch {
                _ = try elements.decode(SkippedElement.self)
                dropped += 1
            }
        }
        self.pins = pins
        droppedCount = dropped
    }
}
