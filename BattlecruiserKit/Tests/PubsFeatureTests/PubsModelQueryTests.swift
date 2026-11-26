import Foundation
import Testing
import PubDBClient
import PubDBModels
@testable import PubsFeature

/// Searches and filters: sent with the fetch; a search ignores the map's area.
@MainActor
struct PubsModelQueryTests {
    private let balham = BoundingBox(west: -0.165, south: 51.42, east: -0.125, north: 51.45)
    private let soho = BoundingBox(west: -0.14, south: 51.51, east: -0.13, north: 51.52)

    @Test func newFiltersRefetchTheSameAreaWithThem() async {
        let source = FakePubSource()
        let model = makeModel(source)
        model.areaChanged(to: balham)
        await model.loadTask?.value

        var open = PubQuery()
        open.openNow = true
        model.queryChanged(open)
        await model.loadTask?.value

        #expect(source.requests.map(\.area) == [balham, balham])
        #expect(source.receivedQueries.last?.openNow == true)
    }

    @Test func aSearchIsSentWithoutAnAreaAndMovingTheMapDoesNotRefetchIt() async {
        let source = FakePubSource()
        let model = makeModel(source)
        model.areaChanged(to: balham)
        await model.loadTask?.value

        var search = PubQuery()
        search.search = "Red Lion"
        model.queryChanged(search)
        await model.loadTask?.value
        model.areaChanged(to: soho)
        await model.loadTask?.value

        #expect(source.requests.map(\.area) == [balham, FakePubSource.noArea])
    }

    @Test func clearingTheSearchFetchesTheLatestArea() async {
        let source = FakePubSource()
        let model = makeModel(source)
        var search = PubQuery()
        search.search = "Red Lion"
        model.queryChanged(search)
        await model.loadTask?.value
        model.areaChanged(to: soho)

        model.queryChanged(PubQuery())
        await model.loadTask?.value

        #expect(source.requests.last?.area == soho)
    }

    private func makeModel(_ source: FakePubSource) -> PubsModel {
        PubsModel(source: source, debounce: .milliseconds(300), sleep: { _ in try Task.checkCancellation() }, now: { Date() })
    }
}
