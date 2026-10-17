import Foundation
import Testing
import PubDBClient
import PubDBModels
@testable import PubDetailFeature

/// The selected pub: instant summary, cached detail, fresh fetch, cancel on switch.
@MainActor
struct PubDetailModelTests {
    private let user = Coordinate(latitude: 51.4431, longitude: -0.1525)

    @Test func selectingShowsTheSummaryAtOnceThenTheDetail() async {
        let source = FakeDetailSource()
        let model = PubDetailModel(source: source)
        let tapped = DetailFixtures.summary(id: "node/1")

        model.select(tapped, near: user)

        // Before any fetch completes, the sheet has something to show.
        let immediateName = model.summary?.name
        #expect(immediateName == "The Test Arms")
        #expect(model.detail == nil)

        await model.loadTask?.value

        #expect(model.detail?.id == "node/1")
        #expect(!model.isLoading)
        #expect(source.requests == [FakeDetailSource.Request(id: "node/1", location: user)])
    }

    @Test func reopeningARecentPubShowsTheCachedDetailAtOnceThenRefreshes() async {
        let source = FakeDetailSource { DetailFixtures.detail(id: $0, name: "Before") }
        let model = PubDetailModel(source: source)
        let pub = DetailFixtures.summary(id: "node/1")
        model.select(pub, near: nil)
        await model.loadTask?.value
        model.deselect()

        source.script { DetailFixtures.detail(id: $0, name: "After") }
        model.select(pub, near: nil)

        let cachedName = model.detail?.summary.name
        #expect(cachedName == "Before")

        await model.loadTask?.value

        let freshName = model.detail?.summary.name
        #expect(freshName == "After")
    }

    @Test func switchingPubsQuicklyFetchesOnlyTheLastOne() async {
        let source = FakeDetailSource()
        let model = PubDetailModel(source: source)

        model.select(DetailFixtures.summary(id: "node/1"), near: nil)
        model.select(DetailFixtures.summary(id: "node/2"), near: nil)
        await model.loadTask?.value

        let ids = source.requests.map { $0.id }
        #expect(ids == ["node/2"])
        #expect(model.detail?.id == "node/2")
    }

    @Test func aFailureKeepsTheCachedDetailAndRecordsTheError() async {
        let source = FakeDetailSource()
        let model = PubDetailModel(source: source)
        let pub = DetailFixtures.summary(id: "node/1")
        model.select(pub, near: nil)
        await model.loadTask?.value

        let offline = PubDBError.transport(URLError(.notConnectedToInternet))
        source.script { _ in throw offline }
        model.select(pub, near: nil)
        await model.loadTask?.value

        #expect(model.detail?.id == "node/1")
        #expect(model.lastError == offline)
        #expect(!model.isLoading)
    }

    @Test func aFailureWithNothingCachedStillShowsTheSummary() async {
        let source = FakeDetailSource { _ in throw PubDBError.http(status: 502) }
        let model = PubDetailModel(source: source)

        model.select(DetailFixtures.summary(id: "node/1"), near: nil)
        await model.loadTask?.value

        #expect(model.detail == nil)
        #expect(model.summary?.id == "node/1")
        #expect(model.lastError == .http(status: 502))
    }

    @Test func retryFetchesTheSelectedPubAgain() async {
        let source = FakeDetailSource { _ in throw PubDBError.http(status: 502) }
        let model = PubDetailModel(source: source)
        model.select(DetailFixtures.summary(id: "node/1"), near: nil)
        await model.loadTask?.value

        source.script { DetailFixtures.detail(id: $0) }
        model.retry()
        await model.loadTask?.value

        #expect(model.detail?.id == "node/1")
        #expect(model.lastError == nil)
        #expect(source.requests.count == 2)
    }

    @Test func deselectingClearsEverything() async {
        let model = PubDetailModel(source: FakeDetailSource())
        model.select(DetailFixtures.summary(id: "node/1"), near: nil)
        await model.loadTask?.value

        model.deselect()

        #expect(model.selected == nil)
        #expect(model.detail == nil)
        #expect(model.summary == nil)
        #expect(!model.isLoading)
    }

    @Test func theCacheForgetsTheLeastRecentlyFetchedPubBeyondItsLimit() async {
        let model = PubDetailModel(source: FakeDetailSource(), cacheLimit: 2)
        for id in ["node/1", "node/2", "node/3"] {
            model.select(DetailFixtures.summary(id: id), near: nil)
            await model.loadTask?.value
        }

        // node/1 was pushed out; node/3 is still there.
        model.select(DetailFixtures.summary(id: "node/1"), near: nil)
        let evicted = model.detail
        #expect(evicted == nil)
        await model.loadTask?.value

        model.select(DetailFixtures.summary(id: "node/3"), near: nil)
        let kept = model.detail?.id
        #expect(kept == "node/3")
    }
}
