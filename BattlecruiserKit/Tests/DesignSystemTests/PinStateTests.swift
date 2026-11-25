import Testing
@testable import DesignSystem

/// "Open is loud, closed is quiet" (spec, "Building a map").
@MainActor
struct PinStateTests {
    private let quietToLoud: [PinState] = [.gone, .paused, .closed, .unknown, .closing, .open]

    @Test func rankMatchesTheServersOrder() {
        #expect(quietToLoud.map(\.rank) == Array(0...5))
    }

    @Test func louderStatesAreNeverSmallerOrFainter() {
        for (quieter, louder) in zip(quietToLoud, quietToLoud.dropFirst()) {
            #expect(quieter.dotRadius <= louder.dotRadius)
            #expect(quieter.dotOpacity <= louder.dotOpacity)
            #expect(quieter.pinSize <= louder.pinSize)
        }
    }

    @Test func onlyOpenAndClosingAreOutlined() {
        #expect(PinState.allCases.filter(\.hasOutline) == [.open, .closing])
    }

    @Test func theServersPinValuesAllParse() {
        for raw in ["open", "closing", "unknown", "closed", "paused", "gone"] {
            #expect(PinState(rawValue: raw) != nil)
        }
    }
}
