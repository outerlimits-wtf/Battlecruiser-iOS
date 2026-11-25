import Foundation
import PubDBModels

/// The map's pins.
extension PubDBClient {
    /// Every pin for these filters, or `.unchanged` when they are the same as
    /// last time (`If-None-Match`). Decoded off the main actor: it is about
    /// 1.3 MB of JSON for all of London.
    public func pins(amenity: String = PubDBClient.defaultAmenity) async throws -> Conditional<PinCollection> {
        try await sendConditional(.pins(amenity: amenity))
    }
}
