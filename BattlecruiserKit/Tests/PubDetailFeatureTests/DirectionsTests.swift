import Foundation
import Testing
@testable import PubDetailFeature

/// The same three links as the web's `lib/directions.ts`.
@MainActor
struct DirectionsTests {
    @Test func threeAppsByCoordinateWithTheNameEncoded() {
        let links = DirectionsLink.all(name: "The Bedford & Co", latitude: 51.44, longitude: -0.15)

        #expect(links.map(\.id) == ["google", "citymapper", "apple"])
        #expect(links[0].url.absoluteString == "https://www.google.com/maps/dir/?api=1&destination=51.44,-0.15")
        #expect(links[1].url.absoluteString.contains("endcoord=51.44,-0.15&endname=The%20Bedford%20%26%20Co"))
        #expect(links[2].url.absoluteString.contains("daddr=51.44,-0.15&q=The%20Bedford%20%26%20Co"))
    }
}
