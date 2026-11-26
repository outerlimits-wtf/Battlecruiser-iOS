import SwiftUI

/// Where the scroll view inside a `BottomSheet` is, so that at full a pull
/// down from the top moves the sheet instead of the content (no pull to
/// refresh). The sheet owns one and hands it down; the scroll view fills it in
/// through `sheetScrollable()`.
@MainActor
@Observable
final class SheetScrollState {
    /// Scrolled all the way up, or pulled past the top.
    var isAtTop = true
    /// How far the content is pulled past the top (the scroll view's bounce).
    /// The sheet takes this off its own drag, so the content follows the
    /// finger rather than moving twice as fast.
    var overscroll: CGFloat = 0
}

public extension View {
    /// Put this on the scroll view a `BottomSheet` holds, so a pull down from
    /// the top brings the sheet down. Does nothing outside a sheet.
    func sheetScrollable() -> some View {
        modifier(SheetScrollTracking())
    }
}

private struct SheetScrollTracking: ViewModifier {
    @Environment(SheetScrollState.self) private var state: SheetScrollState?

    func body(content: Content) -> some View {
        content.onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, distance in
            guard let state else { return }
            state.isAtTop = distance <= 1
            state.overscroll = max(0, -distance)
        }
        // A new scroll view (the list swapped for a pub) starts at its top.
        .onAppear {
            state?.isAtTop = true
            state?.overscroll = 0
        }
    }
}
