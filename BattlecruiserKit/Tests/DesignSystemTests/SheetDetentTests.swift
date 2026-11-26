import CoreGraphics
import Testing
@testable import DesignSystem

/// The same rules as the web's `lib/sheet.test.ts`.
@MainActor
struct SheetDetentTests {
    private let height: CGFloat = 700

    @Test func offsetsGrowFromFullToPeek() {
        #expect(SheetDetent.full.offset(in: height) == 0)
        #expect(SheetDetent.half.offset(in: height) == 322)
        #expect(SheetDetent.peek.offset(in: height) == 622)
    }

    @Test func peekShowsMoreWhenTheSheetRunsUnderTheTabBar() {
        let peek = SheetDetent.peekHeight + 83
        #expect(SheetDetent.peek.offset(in: height, peek: peek) == 539)
        #expect(SheetDetent.half.offset(in: height, peek: peek) == 322)
        #expect(SheetDetent.snap(offset: 539, velocity: 900, height: height, peek: peek) == .peek)
        #expect(SheetDetent.snap(offset: 520, velocity: 0, height: height, peek: peek) == .peek)
    }

    @Test func aGentleReleaseSettlesOnTheNearest() {
        #expect(SheetDetent.snap(offset: 40, velocity: 0, height: height) == .full)
        #expect(SheetDetent.snap(offset: 300, velocity: 0, height: height) == .half)
        #expect(SheetDetent.snap(offset: 600, velocity: 0, height: height) == .peek)
    }

    @Test func aFlickGoesOneStepTheWayItWasGoingEvenIfItBarelyMoved() {
        #expect(SheetDetent.snap(offset: 330, velocity: 900, height: height) == .peek)
        #expect(SheetDetent.snap(offset: 315, velocity: -900, height: height) == .full)
        #expect(SheetDetent.snap(offset: 0, velocity: 900, height: height) == .half)
    }

    @Test func flickingPastTheEndsStaysAtTheEnds() {
        #expect(SheetDetent.snap(offset: 622, velocity: 900, height: height) == .peek)
        #expect(SheetDetent.snap(offset: 0, velocity: -900, height: height) == .full)
    }

    @Test func tappingTheGrabberCyclesUpThenDown() {
        #expect(SheetDetent.peek.next == .half)
        #expect(SheetDetent.half.next == .full)
        #expect(SheetDetent.full.next == .peek)
    }
}
