import PubDBClient
import PubDBModels

/// Where `PinsModel` gets pins from. `PubDBClient` in the app; a fake in tests.
public protocol PinsSource: Sendable {
    func fetchPins(amenity: String) async throws -> Conditional<PinCollection>
}

extension PubDBClient: PinsSource {
    public nonisolated func fetchPins(amenity: String) async throws -> Conditional<PinCollection> {
        try await pins(amenity: amenity)
    }
}
