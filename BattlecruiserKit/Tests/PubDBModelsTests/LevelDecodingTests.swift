import Foundation
import Testing
@testable import PubDBModels

/// Levels as proposed in server ask S16; absent today, and that must be fine.
struct LevelDecodingTests {
    @Test func aLevelAsProposed() throws {
        let json = #"""
        { "key": "regular", "name": "Regular", "line": "They start pouring when you walk in", "emoji": "🍺",
          "xp": 640, "xpLabel": "640 XP",
          "next": { "name": "Lock-in", "atXp": 1500, "remainingLabel": "860 XP to Lock-in" }, "progress": 0.14 }
        """#
        let level = try JSONDecoder().decode(Level.self, from: Data(json.utf8))
        #expect(level.next?.remainingLabel == "860 XP to Lock-in")
    }

    @Test func todaysPayloadsHaveNoLevelAndStillDecode() throws {
        #expect(try Fixture.decode(Profile.self, from: "profile").level == nil)
        #expect(try Fixture.decode(Meta.self, from: "meta").levels == nil)
        #expect(try Fixture.decode(Leaderboard.self, from: "leaderboard").contributors.first?.level == nil)
    }
}
