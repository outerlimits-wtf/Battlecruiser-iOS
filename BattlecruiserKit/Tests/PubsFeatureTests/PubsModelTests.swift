import Foundation
import Testing
import PubDBClient
import PubDBModels
@testable import PubsFeature

/// How the model follows the map: debounce, cancel, skip, keep data on failure.
@MainActor
struct PubsModelTests {
    private let balham = BoundingBox(west: -0.165, south: 51.42, east: -0.125, north: 51.45)
    private let user = Coordinate(latitude: 51.4431, longitude: -0.1525)
    private let fixedNow = Date(timeIntervalSince1970: 1_760_560_200)

    @Test func anAreaChangeFetchesThatAreaAndPublishesPubsInDisplayOrder() async {
        let source = FakePubSource { _ in
            PubFixtures.list([("closed", "closed", 10), ("open", "open", 50)])
        }
        let model = makeModel(source)

        model.areaChanged(to: balham)
        await model.loadTask?.value

        #expect(source.requests == [.init(area: balham, location: nil)])
        let ids = model.pubs.map { $0.id }
        #expect(ids == ["open", "closed"])
        #expect(model.openCount == 1)
        #expect(model.fetchedAt == fixedNow)
        #expect(!model.isLoading)
        #expect(model.lastError == nil)
    }

    @Test func rapidChangesFetchOnlyTheLastArea() async {
        let source = FakePubSource()
        let model = makeModel(source)
        let elsewhere = BoundingBox(west: 0.0, south: 51.5, east: 0.04, north: 51.53)

        model.areaChanged(to: balham)
        model.areaChanged(to: elsewhere)
        await model.loadTask?.value

        #expect(source.requests == [.init(area: elsewhere, location: nil)])
    }

    @Test func anAreaInsideTheLastOneIsNotFetchedAgain() async {
        let source = FakePubSource()
        let model = makeModel(source)
        model.areaChanged(to: balham)
        await model.loadTask?.value

        // Slightly smaller, same centre: still covered.
        model.areaChanged(to: BoundingBox(west: -0.16, south: 51.425, east: -0.13, north: 51.445))
        await model.loadTask?.value

        #expect(source.requests.count == 1)
    }

    @Test func zoomingWellInFetchesAgain() async {
        let source = FakePubSource()
        let model = makeModel(source)
        model.areaChanged(to: balham)
        await model.loadTask?.value

        // Inside, but under half as wide: the wider fetch may have left pubs out.
        model.areaChanged(to: BoundingBox(west: -0.15, south: 51.43, east: -0.14, north: 51.44))
        await model.loadTask?.value

        #expect(source.requests.count == 2)
    }

    @Test func panningOutsideTheLastAreaFetchesAgain() async {
        let source = FakePubSource()
        let model = makeModel(source)
        model.areaChanged(to: balham)
        await model.loadTask?.value

        model.areaChanged(to: BoundingBox(west: -0.145, south: 51.42, east: -0.105, north: 51.45))
        await model.loadTask?.value

        #expect(source.requests.count == 2)
    }

    @Test func aFailureKeepsThePubsAlreadyShownAndRecordsTheError() async {
        let source = FakePubSource { _ in PubFixtures.list([("open", "open", 10)]) }
        let model = makeModel(source)
        model.areaChanged(to: balham)
        await model.loadTask?.value

        let offline = PubDBError.transport(URLError(.notConnectedToInternet))
        source.script { _ in throw offline }
        model.areaChanged(to: BoundingBox(west: 0.0, south: 51.5, east: 0.04, north: 51.53))
        await model.loadTask?.value

        let ids = model.pubs.map { $0.id }
        #expect(ids == ["open"])
        #expect(model.lastError == offline)
        #expect(!model.isLoading)
    }

    @Test func afterAFailureEvenACoveredAreaRetries() async {
        let source = FakePubSource { _ in throw PubDBError.http(status: 502) }
        let model = makeModel(source)
        model.areaChanged(to: balham)
        await model.loadTask?.value

        source.script { _ in PubFixtures.list([]) }
        model.areaChanged(to: BoundingBox(west: -0.16, south: 51.425, east: -0.13, north: 51.445))
        await model.loadTask?.value

        #expect(source.requests.count == 2)
        #expect(model.lastError == nil)
    }

    @Test func refreshFetchesTheSameAreaAgain() async {
        let source = FakePubSource()
        let model = makeModel(source)
        model.areaChanged(to: balham)
        await model.loadTask?.value

        model.refresh()
        await model.loadTask?.value

        let areas = source.requests.map { $0.area }
        #expect(areas == [balham, balham])
    }

    @Test func theFirstLocationFixRefetchesWithTheLocation() async {
        let source = FakePubSource()
        let model = makeModel(source)
        model.areaChanged(to: balham)
        await model.loadTask?.value

        model.userLocationChanged(to: user)
        await model.loadTask?.value

        let lastRequest = source.requests.last
        #expect(lastRequest == FakePubSource.Request(area: balham, location: user))
    }

    @Test func laterLocationUpdatesDoNotRefetchByThemselves() async {
        let source = FakePubSource()
        let model = makeModel(source)
        model.userLocationChanged(to: user)
        model.areaChanged(to: balham)
        await model.loadTask?.value

        model.userLocationChanged(to: Coordinate(latitude: 51.444, longitude: -0.152))
        await model.loadTask?.value

        #expect(source.requests.count == 1)
    }

    @Test func loadIfIdleFetchesWhenNothingHasBeenAskedFor() async {
        let source = FakePubSource()
        let model = makeModel(source)

        model.loadIfIdle(in: balham)
        await model.loadTask?.value

        let areas = source.requests.map { $0.area }
        #expect(areas == [balham])
    }

    @Test func loadIfIdleDoesNothingOnceTheMapHasReportedAnArea() async {
        let source = FakePubSource()
        let model = makeModel(source)
        let elsewhere = BoundingBox(west: 0.0, south: 51.5, east: 0.04, north: 51.53)
        model.areaChanged(to: elsewhere)

        model.loadIfIdle(in: balham)
        await model.loadTask?.value

        let areas = source.requests.map { $0.area }
        #expect(areas == [elsewhere])
    }

    // MARK: - Helpers

    /// No real waiting: the debounce "sleep" only checks for cancellation, which
    /// is what a superseded load sees.
    private func makeModel(_ source: FakePubSource) -> PubsModel {
        let fixedNow = fixedNow
        return PubsModel(
            source: source,
            debounce: .milliseconds(300),
            sleep: { _ in
                try Task.checkCancellation()
            },
            now: { fixedNow }
        )
    }
}
