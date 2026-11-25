import Foundation
import Testing
import PubDBClient
import PubDBModels
@testable import PubsMap

@MainActor
struct PinsModelTests {
    private static let pin = Pin(
        id: "node/1", latitude: 51.5, longitude: -0.1, name: "The Test", area: nil,
        amenity: "pub", state: "open", rank: 5, emoji: "🍺", label: "Open till 23:00"
    )

    @Test func aNewBodyReplacesThePins() async {
        let source = FakePinsSource([.changed(PinCollection(pins: [Self.pin]))])
        let model = PinsModel(source: source)

        model.refresh()
        await model.loadTask?.value

        #expect(model.pins == [Self.pin])
        #expect(model.confirmedAt != nil)
    }

    @Test func a304KeepsTheSamePins() async {
        let source = FakePinsSource([.changed(PinCollection(pins: [Self.pin])), .unchanged])
        let model = PinsModel(source: source)

        model.refresh()
        await model.loadTask?.value
        model.refresh()
        await model.loadTask?.value

        #expect(model.pins == [Self.pin])
        #expect(source.calls == 2)
    }

    @Test func aFailureKeepsThePinsAndRecordsTheError() async {
        let source = FakePinsSource([.changed(PinCollection(pins: [Self.pin]))], thenFail: URLError(.notConnectedToInternet))
        let model = PinsModel(source: source)

        model.refresh()
        await model.loadTask?.value
        model.refresh()
        await model.loadTask?.value

        #expect(model.pins == [Self.pin])
        #expect(model.lastError?.isOffline == true)
        #expect(!model.isLoading)
    }

    @Test func sameFiltersDoNotRefetch() async {
        let source = FakePinsSource([])
        let model = PinsModel(source: source, amenity: "pub")

        model.filtersChanged(amenity: "pub")
        await model.loadTask?.value

        #expect(source.calls == 0)
    }

    @Test func newFiltersFetchWithThem() async {
        let source = FakePinsSource([.changed(PinCollection(pins: []))])
        let model = PinsModel(source: source, amenity: "pub")

        model.filtersChanged(amenity: "bar")
        await model.loadTask?.value

        #expect(source.amenities == ["bar"])
    }
}

private final class FakePinsSource: PinsSource, @unchecked Sendable {
    private let lock = NSLock()
    private var answers: [Conditional<PinCollection>]
    private let failure: (any Error)?
    private var recorded: [String] = []

    init(_ answers: [Conditional<PinCollection>], thenFail failure: (any Error)? = nil) {
        self.answers = answers
        self.failure = failure
    }

    var calls: Int { lock.withLock { recorded.count } }
    var amenities: [String] { lock.withLock { recorded } }

    func fetchPins(amenity: String) async throws -> Conditional<PinCollection> {
        let next: Conditional<PinCollection>? = lock.withLock {
            recorded.append(amenity)
            return answers.isEmpty ? nil : answers.removeFirst()
        }
        if let next { return next }
        throw failure ?? CancellationError()
    }
}
