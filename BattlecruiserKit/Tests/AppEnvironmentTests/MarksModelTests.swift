import Foundation
import Testing
import PubDBClient
import PubDBModels
@testable import AppEnvironment

@MainActor
struct MarksModelTests {
    private final class Source: MarksSource, @unchecked Sendable {
        var fails = false
        func fetchSavedIDs(_ list: SavedList) async throws -> Set<String> { list == .watchlist ? ["a"] : [] }
        func setMark(_ pubID: String, on list: SavedList, _ on: Bool) async throws -> PubMark {
            if fails { throw URLError(.notConnectedToInternet) }
            return try JSONDecoder().decode(PubMark.self, from: Data(#"{"pubId":"\#(pubID)","watching":\#(on)}"#.utf8))
        }
    }

    @Test func loadsBothListsAndTogglesStick() async {
        let model = MarksModel(source: Source())
        await model.load()
        #expect(model.contains("a", on: .watchlist))

        await model.toggle("b", on: .visited)
        #expect(model.contains("b", on: .visited))
    }

    @Test func aRefusedToggleIsPutBack() async {
        let source = Source()
        source.fails = true
        let model = MarksModel(source: source)
        await model.load()

        await model.toggle("a", on: .watchlist)

        #expect(model.contains("a", on: .watchlist))
    }
}
