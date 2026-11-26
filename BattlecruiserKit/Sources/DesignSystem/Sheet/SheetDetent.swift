import CoreGraphics

/// Where the bottom sheet rests (the web's `lib/sheet.ts`). An offset is how
/// far the sheet is pushed down from filling its space: 0 is full.
public enum SheetDetent: CaseIterable, Sendable {
    case full
    case half
    case peek

    /// How much of the sheet still shows above the tab bar when it is pushed down.
    public static let peekHeight: CGFloat = 78
    /// Where it rests by default, as a fraction of its own height.
    static let halfFraction: CGFloat = 0.46
    /// Past this, a flick beats where the thumb let go (the web's 0.4 px/ms).
    static let flickVelocity: CGFloat = 400

    /// - Parameter peek: How much shows at peek: `peekHeight`, plus whatever
    ///   the sheet runs underneath at the bottom (the floating tab bar).
    func offset(in height: CGFloat, peek: CGFloat = peekHeight) -> CGFloat {
        switch self {
        case .full: 0
        case .half: (height * Self.halfFraction).rounded()
        case .peek: max(0, height - peek)
        }
    }

    /// Flick it and it carries on the way it was going, one position at a
    /// time; let go gently and it settles wherever is nearest.
    /// - Parameter velocity: Points per second, positive downwards.
    static func snap(offset: CGFloat, velocity: CGFloat, height: CGFloat, peek: CGFloat = peekHeight) -> SheetDetent {
        let resting = allCases.map { (detent: $0, at: $0.offset(in: height, peek: peek)) }
        if velocity > flickVelocity {
            return resting.first { $0.at > offset + 1 }?.detent ?? .peek
        }
        if velocity < -flickVelocity {
            return resting.reversed().first { $0.at < offset - 1 }?.detent ?? .full
        }
        return resting.min { abs($0.at - offset) < abs($1.at - offset) }?.detent ?? .half
    }

    /// What tapping the grabber does: up, up, then back down out of the way.
    var next: SheetDetent {
        switch self {
        case .peek: .half
        case .half: .full
        case .full: .peek
        }
    }

    /// What tapping the grabber will do, for VoiceOver.
    var grabberLabel: String {
        switch self {
        case .peek: "Open the list"
        case .half: "Fill the screen"
        case .full: "Shrink the list"
        }
    }
}
