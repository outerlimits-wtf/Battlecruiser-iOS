import Foundation
import Testing
import PubDBModels
@testable import AppEnvironment

/// Only people get a profile link: a data source or someone anonymous doesn't.
struct ProfileLinkTests {
    @Test func aPersonLinksToTheirProfileWithoutTheAt() throws {
        let link = try #require(ProfileLink(Self.attribution(kind: "user", label: "@goatloaf")))
        #expect(link.username == "goatloaf")
    }

    @Test func aSourceOrAnAnonymousReviewHasNoProfile() throws {
        #expect(ProfileLink(try Self.attribution(kind: "source", label: "OpenStreetMap")) == nil)
        #expect(ProfileLink(try Self.attribution(kind: "anonymous", label: "Someone")) == nil)
        #expect(ProfileLink(try Self.attribution(kind: "user", label: "@")) == nil)
    }

    private static func attribution(kind: String, label: String) throws -> Attribution {
        let json = #"{"kind": "\#(kind)", "label": "\#(label)", "sourceKey": null}"#
        return try JSONDecoder().decode(Attribution.self, from: Data(json.utf8))
    }
}
