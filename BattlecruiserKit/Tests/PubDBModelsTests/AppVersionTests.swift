import Testing
@testable import PubDBModels

/// `clients.ios.minVersion` is compared part by part, as numbers (spec, `/meta`).
struct AppVersionTests {
    @Test func partsCompareAsNumbersNotText() throws {
        let tenth = try #require(AppVersion("0.10"))
        let ninth = try #require(AppVersion("0.9"))

        #expect(ninth < tenth)
    }

    @Test func missingPartsCountAsZero() throws {
        #expect(try #require(AppVersion("1")) == #require(AppVersion("1.0.0")))
        #expect(try #require(AppVersion("1.0")) < #require(AppVersion("1.0.1")))
    }

    @Test func nonsenseIsNotAVersion() {
        #expect(AppVersion("") == nil)
        #expect(AppVersion("1.x") == nil)
        #expect(AppVersion("1..2") == nil)
    }

    @Test func noFloorOrAnUnreadableFloorLetsTheBuildRun() throws {
        let build = try #require(AppVersion("0.1"))

        #expect(build.isAllowed(minimum: nil))
        #expect(build.isAllowed(minimum: "garbage"))
    }

    @Test func aBuildBelowTheFloorIsNotAllowed() throws {
        let build = try #require(AppVersion("0.9"))

        #expect(!build.isAllowed(minimum: "0.10"))
        #expect(build.isAllowed(minimum: "0.9"))
        #expect(build.isAllowed(minimum: "0.8.5"))
    }
}
