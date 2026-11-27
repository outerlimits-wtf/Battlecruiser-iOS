import Testing
import PubDBModels
@testable import PubDetailFeature

struct OperatorMatchesTests {
    private let all = [
        Brand(name: "Greene King", count: 185),
        Brand(name: "Wetherspoon", count: 109),
        Brand(name: "Young's", count: 51),
        Brand(name: "Café Rouge Inns", count: 2),
    ]

    @Test func nothingTypedOffersTheBiggestFirst() {
        let matches = OperatorMatches(typed: "  ", in: all, limit: 2)
        #expect(matches.brands.map(\.name) == ["Greene King", "Wetherspoon"])
        #expect(matches.newName == nil)
    }

    @Test func typingFiltersIgnoringCaseAndAccents() {
        #expect(OperatorMatches(typed: "spoon", in: all).brands.map(\.name) == ["Wetherspoon"])
        #expect(OperatorMatches(typed: "cafe", in: all).brands.map(\.name) == ["Café Rouge Inns"])
    }

    @Test func aKnownNameIsNotOfferedAsNew() {
        #expect(OperatorMatches(typed: "young's ", in: all).newName == nil)
    }

    @Test func anUnknownNameCanBeSavedTrimmed() {
        let matches = OperatorMatches(typed: "Punch Pubs  \n", in: all)
        #expect(matches.brands.isEmpty)
        #expect(matches.newName == "Punch Pubs")
    }

    @Test func aPartMatchStillOffersTheTypedNameAsNew() {
        let matches = OperatorMatches(typed: "King", in: all)
        #expect(matches.brands.map(\.name) == ["Greene King"])
        #expect(matches.newName == "King")
    }
}
