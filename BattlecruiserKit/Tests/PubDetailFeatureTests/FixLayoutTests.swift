import Foundation
import Testing
import PubDBModels
@testable import PubDetailFeature

/// The Fix panel is laid out from meta's `section` and `order`, never by key.
@MainActor
struct FixLayoutTests {
    private func fields(_ json: String) throws -> [ContributableField] {
        try JSONDecoder().decode([ContributableField].self, from: Data(json.utf8))
    }

    @Test func groupsBySectionInOrderAndSkipsHistory() throws {
        let fields = try fields("""
        [
          {"key": "garden", "label": "Beer garden", "kind": "tri", "section": "features", "order": 9},
          {"key": "status", "label": "Still there?", "kind": "status", "section": "listing", "order": 32},
          {"key": "previous_name", "label": "Previous name", "kind": "previous_name", "section": "history", "order": 29},
          {"key": "website", "label": "Website", "kind": "url", "section": "details", "order": 4},
          {"key": "name", "label": "Name", "kind": "text", "section": "details", "order": 1}
        ]
        """)
        let layout = FixLayout(fields: fields, editable: [:])

        #expect(layout.groups.map(\.id) == ["details", "features", "listing"])
        #expect(layout.groups.first?.items.map(\.id) == ["name", "website"])
    }

    @Test func unknownSectionsComeLastAndOlderServersFallIntoDetails() throws {
        let fields = try fields("""
        [
          {"key": "cellar", "label": "Cellar", "kind": "text", "section": "beer_cellar", "order": 1},
          {"key": "garden", "label": "Beer garden", "kind": "tri", "section": "features", "order": 9},
          {"key": "brewery", "label": "Brewery", "kind": "text"},
          {"key": "phone", "label": "Phone", "kind": "phone"}
        ]
        """)
        let layout = FixLayout(fields: fields, editable: [:])

        #expect(layout.groups.map(\.id) == ["features", "details", "beer_cellar"])
        // No order: after those with one, in meta's order.
        #expect(layout.groups[1].items.map(\.id) == ["brewery", "phone"])
        #expect(layout.groups[2].title == "Beer cellar")
    }

    @Test func eachItemCarriesWhatThePubHasNow() throws {
        let fields = try fields("""
        [{"key": "guinness_price", "label": "Guinness", "kind": "price", "section": "tonight", "order": 26}]
        """)
        let layout = FixLayout(
            fields: fields,
            editable: ["guinness_price": EditableValue(value: "730", display: "£7.30")]
        )

        #expect(layout.groups.first?.items.first?.current?.display == "£7.30")
    }
}
