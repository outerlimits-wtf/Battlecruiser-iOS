import Testing
@testable import Battlecruiser

/// App-level tests only: module tests live in each package's own test target
/// (decision D24). This keeps the BattlecruiserTests target valid until there
/// is app wiring worth testing; replace it once there is.
struct AppSmokeTests {
    @Test func appModuleLoads() {
        #expect(Bool(true))
    }
}
