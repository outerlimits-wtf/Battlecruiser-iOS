import Testing
import PubDBModels
@testable import DesignSystem

/// Which pins are loud and which are quiet (docs/mvp-plan.md, "Pins").
struct PinEmphasisTests {
    @Test func openIsOpen() {
        let emphasis = PinEmphasis(state: .open, serving: true, closingSoon: false)

        #expect(emphasis == .open)
    }

    @Test func openWithinTheHourIsClosingSoon() {
        let emphasis = PinEmphasis(state: .open, serving: true, closingSoon: true)

        #expect(emphasis == .closingSoon)
    }

    @Test func unknownHoursStayUnknown() {
        let emphasis = PinEmphasis(state: .unknown, serving: true, closingSoon: false)

        #expect(emphasis == .unknown)
    }

    @Test func closedIsClosed() {
        let emphasis = PinEmphasis(state: .closed, serving: true, closingSoon: false)

        #expect(emphasis == .closed)
    }

    @Test func aPubThatIsNotTradingIsClosedWhateverItsHoursSay() {
        let openButShut = PinEmphasis(state: .open, serving: false, closingSoon: false)
        let unknownAndShut = PinEmphasis(state: .unknown, serving: false, closingSoon: false)

        #expect(openButShut == .closed)
        #expect(unknownAndShut == .closed)
    }

    @Test func openPinsDrawAboveUnknownAboveClosed() {
        let open = PinEmphasis.open.drawOrder
        let closingSoon = PinEmphasis.closingSoon.drawOrder
        let unknown = PinEmphasis.unknown.drawOrder
        let closed = PinEmphasis.closed.drawOrder

        #expect(open == closingSoon)
        #expect(open > unknown)
        #expect(unknown > closed)
    }

    @Test func openPinsAreBiggestAndClosedSmallest() {
        let open = PinEmphasis.open.diameter
        let unknown = PinEmphasis.unknown.diameter
        let closed = PinEmphasis.closed.diameter

        #expect(open > unknown)
        #expect(unknown > closed)
    }
}
