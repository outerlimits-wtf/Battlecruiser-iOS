import Foundation
import Testing
import PubDBModels
@testable import PubDetailFeature

/// Structured values go as a JSON object, one key per meta part (S5).
@MainActor
struct StructuredValueTests {
    private let parts: [FieldPart] = try! JSONDecoder().decode([FieldPart].self, from: Data("""
    [
      {"key": "state", "label": "What happened", "kind": "status", "optional": false},
      {"key": "year", "label": "Year", "kind": "year", "optional": true},
      {"key": "became", "label": "What it is now", "kind": "text", "optional": true}
    ]
    """.utf8))

    @Test func sendsEachPartWithTheYearAsANumber() {
        let json = StructuredValue.json(parts, values: ["state": "converted", "year": "2019", "became": " a Tesco "])
        #expect(json == #"{"became":"a Tesco","state":"converted","year":2019}"#)
    }

    @Test func leavesEmptyOptionalPartsNull() {
        let json = StructuredValue.json(parts, values: ["state": "closed"])
        #expect(json == #"{"became":null,"state":"closed","year":null}"#)
    }

    @Test func refusesAMissingRequiredPartABadYearOrAPipe() {
        #expect(StructuredValue.json(parts, values: ["year": "2019"]) == nil)
        #expect(StructuredValue.json(parts, values: ["state": "closed", "year": "19"]) == nil)
        #expect(StructuredValue.json(parts, values: ["state": "closed", "became": "flats | shops"]) == nil)
    }

    @Test func listingErrorsAreTheTwoAboutTheRecord() {
        #expect(StatusState.all.filter(\.isListingError).map(\.key) == ["duplicate", "broken"])
        #expect(!StatusState.isListingError("a_state_added_later"))
    }
}
