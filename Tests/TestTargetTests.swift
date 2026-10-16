import Testing
@testable import Battlecruiser

/// Proves the test target is wired to the app: it builds, links against the
/// app module, and runs. Delete once real tests exist alongside it.
struct TestTargetTests {
    @Test func testTargetRuns() {
        #expect(Bool(true))
    }
}
