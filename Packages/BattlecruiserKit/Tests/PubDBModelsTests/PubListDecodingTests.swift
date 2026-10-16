import Foundation
import Testing
@testable import PubDBModels

/// Decodes real `GET /pubs` and `/similar` responses. These check shapes and the
/// specific cases each fixture was chosen for (docs/test-fixtures.md), not exact
/// counts that would drift when the fixtures are refreshed.
struct PubListDecodingTests {
    @Test func thursdayEveningListDecodesEveryPub() throws {
        let list = try Fixture.decode(PubList.self, from: "pubs-list-thu-2230")

        #expect(list.droppedCount == 0)
        #expect(!list.pubs.isEmpty)
        #expect(list.count == list.pubs.count)
    }

    @Test func thursdayEveningListCarriesOpenAndUnknownPubs() throws {
        let list = try Fixture.decode(PubList.self, from: "pubs-list-thu-2230")
        let states = Set(list.pubs.map(\.open.state))

        #expect(states.contains(.open))
        #expect(states.contains(.unknown))
    }

    @Test func openPubsHaveACountdownAndUnknownOnesHaveNoClosingTime() throws {
        let list = try Fixture.decode(PubList.self, from: "pubs-list-thu-2230")

        for pub in list.pubs where pub.open.state == .open {
            #expect(pub.open.countdownLabel != nil, "\(pub.name) is open but has no countdown")
            #expect(pub.open.minutesUntilClose != nil, "\(pub.name) is open but has no minutes until close")
        }
        for pub in list.pubs where pub.open.state == .unknown {
            #expect(pub.open.closesAt == nil, "\(pub.name) has unknown hours but a closing time")
        }
    }

    @Test func everyPubHasADistanceBecauseTheRequestSentALocation() throws {
        let list = try Fixture.decode(PubList.self, from: "pubs-list-thu-2230")

        #expect(list.pubs.allSatisfy { $0.distance != nil })
    }

    @Test func guinnessPricesArriveFormatted() throws {
        let list = try Fixture.decode(PubList.self, from: "pubs-list-thu-2230")
        let priced = list.pubs.compactMap(\.guinness)

        #expect(!priced.isEmpty)
        for guinness in priced {
            #expect(guinness.formatted.hasPrefix("£"))
            #expect(guinness.pence > 0)
        }
    }

    @Test func tonightDecodesWhereSomeoneHasReportedIt() throws {
        let list = try Fixture.decode(PubList.self, from: "pubs-list-thu-2230")
        let earlFerrers = try #require(list.pubs.first(where: { $0.id == "way/1223071579" }))
        let tonight = try #require(earlFerrers.tonight)

        #expect(tonight.kind == "kicked_out")
        #expect(!tonight.label.isEmpty)
        #expect(!tonight.symbol.emoji.isEmpty)
    }

    @Test func lateNightListHasClosedPubsAndNoneOpen() throws {
        let list = try Fixture.decode(PubList.self, from: "pubs-list-fri-0130")
        let states = Set(list.pubs.map(\.open.state))

        #expect(list.droppedCount == 0)
        #expect(states.contains(.closed))
        #expect(!states.contains(.open))
    }

    @Test func similarResponseHasPubsButNoCount() throws {
        let list = try Fixture.decode(PubList.self, from: "pubs-similar-the-bedford")

        #expect(list.droppedCount == 0)
        #expect(!list.pubs.isEmpty)
        #expect(list.count == nil)
    }
}
