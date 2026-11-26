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
            state?.isAtTop = distance <= 1
        }
        // A new scroll view (the list swapped for a pub) starts at its top.
        .onAppear {
            state?.isAtTop = true
        }
    }
}
