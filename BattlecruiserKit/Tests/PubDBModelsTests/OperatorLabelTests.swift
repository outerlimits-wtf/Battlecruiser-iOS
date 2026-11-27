import Testing
@testable import PubDBModels

/// Until S24, the app says "Operator" where `/meta` still says "Owner".
struct OperatorLabelTests {
    @Test func theBrandFieldAndPreviousNamesOwnerReadOperator() throws {
        let meta = try Fixture.decode(Meta.self, from: "meta-1127")
        let brand = try #require(meta.contributableFields.first { $0.key == "brand" })
        #expect(brand.label == "Operator")
        let previous = try #require(meta.contributableFields.first { $0.key == "previous_name" })
        #expect(previous.parts.first { $0.key == "owner" }?.label == "Operator")
    }

    @Test func onlyTheOldLabelOnThoseKeysIsSwapped() {
        #expect(OperatorLabel.label("Pub company", forKey: "brand", keys: ["brand"]) == "Pub company")
        #expect(OperatorLabel.label("Owner", forKey: "name", keys: ["brand"]) == "Owner")
    }
}
