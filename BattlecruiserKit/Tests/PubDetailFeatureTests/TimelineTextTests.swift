import Foundation
import Testing
import PubDBModels
@testable import PubDetailFeature

@MainActor
struct TimelineTextTests {
    private func stop(_ name: String, from: String?, until: String?, current: Bool, owner: String? = nil, kind: String? = nil) throws -> TimelineStop {
        var json: [String: Any] = ["name": name, "isCurrent": current]
        json["fromLabel"] = from
        json["untilLabel"] = until
        json["owner"] = owner
        if let kind { json["attribution"] = ["kind": kind, "label": "Hellcat", "sourceKey": "hellcat"] }
        return try JSONDecoder().decode(TimelineStop.self, from: JSONSerialization.data(withJSONObject: json))
    }

    @Test func spansReadAsTheWebsDo() throws {
        #expect(TimelineText.title(try stop("The Old Larrik", from: "1988", until: "1997", current: false)) == "1988–1997 The Old Larrik")
        #expect(TimelineText.title(try stop("The Bedford", from: "1997", until: nil, current: true)) == "1997– The Bedford (now)")
        #expect(TimelineText.title(try stop("The Bedford", from: nil, until: nil, current: true)) == "The Bedford (now)")
        #expect(TimelineText.title(try stop("The Swan", from: nil, until: "1960", current: false)) == "?–1960 The Swan")
    }

    @Test func importersAreNeverNamed() throws {
        #expect(TimelineText.note(try stop("A", from: nil, until: nil, current: false, owner: "Trumans", kind: "importer")) == "Trumans")
        #expect(TimelineText.note(try stop("A", from: nil, until: nil, current: false, kind: "source")) == "Hellcat")
    }
}
