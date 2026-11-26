import Testing
@testable import PubDetailFeature

@MainActor
struct GuinnessPriceTests {
    @Test func whatPeopleTypeBecomesPence() {
        #expect(GuinnessPrice.pence(from: "5.60") == 560)
        #expect(GuinnessPrice.pence(from: "£6.2") == 620)
        #expect(GuinnessPrice.pence(from: " 7 ") == 700)
        #expect(GuinnessPrice.pence(from: "5,50") == 550)
        #expect(GuinnessPrice.pence(from: "a fiver") == nil)
        #expect(GuinnessPrice.pence(from: "0") == nil)
    }

    @Test func theRefusalNamesTheBounds() {
        #expect(GuinnessPrice.outOfRange("56", min: 200, max: 1500)
                == "£56 does not look right for a pint. Somewhere between £2.00 and £15.00?")
    }
}
