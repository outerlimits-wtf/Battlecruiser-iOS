import SwiftUI

/// The web's bottom sheet: over the map, resting at peek, half or full. Drag
/// the top (grabber and header) to move it; flick to go one step; tap the
/// grabber to cycle. Changing `resetKey` (a new pub) lifts it from peek to
/// half so the new content is seen.
///
/// It runs to the bottom of the screen, under the floating tab bar, and at
/// peek shows `SheetDetent.peekHeight` above the bar. At full its top stops
/// `topInset` below the top of its space, clear of whatever sits there (the
/// search bar and filters), so the grabber can still be reached.
///
/// The content only scrolls at full: below it, a drag anywhere on the content
/// moves the sheet instead, so it always opens all the way before scrolling.
/// At full, a pull down from the top of the content brings the sheet down
/// (the content's scroll view needs `sheetScrollable()` for this).
public struct BottomSheet<Header: View, Content: View>: View {
    @Binding private var detent: SheetDetent
    private let resetKey: AnyHashable?
    private let topInset: CGFloat?
    /// Draw the grabber over the content (a photo running to the top edge)
    /// rather than in a strip above it. The header is not shown.
    private let overlaysGrabber: Bool
    private let header: Header
    private let content: Content

    /// How far the finger has moved the sheet from where it rests. Plain
    /// state, not `@GestureState`, so that letting go animates it back to 0
    /// together with the new detent rather than jumping first.
    @State private var drag: CGFloat = 0
    @GestureState private var isDragging = false
    @GestureState private var isPulling = false
    /// Where the finger was (its translation) when the pull at full under way
    /// took hold of the sheet: once the content is at its top and the finger
    /// is moving down. Nil while the content is still scrolling.
    @State private var pullOrigin: CGFloat?
    @State private var scroll = SheetScrollState()
    /// How much the tab bar (and home indicator) covers at the bottom.
    @State private var bottomInset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Where full stops when no `topInset` is given: the web's 88% sheet.
    static var defaultTopFraction: CGFloat { 0.12 }

    /// - Parameter topInset: How far below the top of its space the sheet
    ///   stops at full. Nil leaves 12% of the space.
    public init(
        detent: Binding<SheetDetent>,
        resetKey: AnyHashable? = nil,
        topInset: CGFloat? = nil,
        overlaysGrabber: Bool = false,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        _detent = detent
        self.resetKey = resetKey
        self.topInset = topInset
        self.overlaysGrabber = overlaysGrabber
        self.header = header()
        self.content = content()
    }

    public var body: some View {
        ZStack {
            // Keeps the safe area, so it sees how much the tab bar covers. The
            // reader below ignores it and so would only ever see zero.
            Color.clear
                .allowsHitTesting(false)
                .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.bottom } action: { bottomInset = $0 }
            sheet
        }
        .onChange(of: resetKey) {
            if detent == .peek { move(to: .half) }
        }
    }

    /// Runs to the bottom of the screen, under the tab bar.
    private var sheet: some View {
        GeometryReader { proxy in
            let layout = SheetLayout(
                height: max(0, proxy.size.height - (topInset ?? proxy.size.height * Self.defaultTopFraction)),
                peek: SheetDetent.peekHeight + bottomInset,
                bottomInset: bottomInset,
                detent: detent
            )
            let offset = min(max(layout.rest + drag, 0), layout.lowest)

            Group {
                if overlaysGrabber {
                    ZStack(alignment: .top) {
                        sheetContent(layout)
                        grabber(onPhoto: true)
                            .gesture(dragGesture(layout))
                    }
                } else {
                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            grabber(onPhoto: false)
                            header
                        }
                        .contentShape(Rectangle())
                        .gesture(dragGesture(layout))
                        sheetContent(layout)
                    }
                }
            }
            .frame(height: layout.height)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: Metrics.sheetRadius, topTrailingRadius: Metrics.sheetRadius))
            .background(
                UnevenRoundedRectangle(topLeadingRadius: Metrics.sheetRadius, topTrailingRadius: Metrics.sheetRadius)
                    .fill(Palette.surface)
                    .shadow(color: .black.opacity(0.24), radius: 14, y: -3)
            )
            // Pinned to the bottom of the reader, which is the screen's edge.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .offset(y: offset)
            // A drag the system took away (no onEnded): settle where it is.
            .onChange(of: isDragging || isPulling) { _, isActive in
                guard !isActive else { return }
                pullOrigin = nil
                if drag != 0 { settle(layout, velocity: 0) }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }

    /// Scrolls only at full; below it, dragging the content moves the sheet.
    private func sheetContent(_ layout: SheetLayout) -> some View {
        content
            // Ignoring the safe area took the tab bar's inset away from the
            // content too; give it back so the last row scrolls clear of the bar.
            .safeAreaPadding(.bottom, layout.bottomInset)
            .frame(maxHeight: .infinity, alignment: .top)
            .opacity(detent == .peek && drag == 0 ? 0 : 1)
            .scrollDisabled(detent != .full)
            .environment(scroll)
            .gesture(dragGesture(layout), including: detent == .full ? .subviews : .all)
            .simultaneousGesture(pullGesture(layout), including: detent == .full ? .all : .subviews)
    }

    private func grabber(onPhoto: Bool) -> some View {
        Button {
            move(to: detent.next)
        } label: {
            Capsule()
                .fill(onPhoto ? Color.white.opacity(0.9) : Palette.ink.opacity(0.25))
                .shadow(color: .black.opacity(onPhoto ? 0.35 : 0), radius: 2)
                .frame(width: 44, height: 6)
                // Tall and wide, so it is easy to catch at full, just under
                // the filters.
                .frame(width: 160, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(detent.grabberLabel)
    }

    /// Measured on the screen, not in the sheet: the sheet moves under the
    /// finger, so in its own space the translation would shift with every
    /// move and the sheet would flicker between two positions.
    private func dragGesture(_ layout: SheetLayout) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .global)
            .updating($isDragging) { _, isDragging, _ in isDragging = true }
            .onChanged { value in drag = value.translation.height }
            .onEnded { value in settle(layout, velocity: value.velocity.height) }
    }

    /// At full, alongside the content's scrolling: pulling down with the
    /// content at its top moves the whole sheet, whether the pull started
    /// there or scrolled back up to it. The sheet follows the finger exactly,
    /// which carries the scroll view along with it, so the content never
    /// stretches away from the top as if to refresh.
    private func pullGesture(_ layout: SheetLayout) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .global)
            .updating($isPulling) { _, isPulling, _ in isPulling = true }
            .onChanged { value in
                let y = value.translation.height
                if pullOrigin == nil, scroll.isAtTop, value.velocity.height > 0 {
                    pullOrigin = y
                }
                guard let pullOrigin else { return }
                drag = max(0, y - pullOrigin)
            }
            .onEnded { value in
                defer { pullOrigin = nil }
                guard pullOrigin != nil else { return }
                settle(layout, velocity: value.velocity.height)
            }
    }

    private func settle(_ layout: SheetLayout, velocity: CGFloat) {
        move(to: SheetDetent.snap(
            offset: layout.rest + drag,
            velocity: velocity,
            height: layout.height,
            peek: layout.peek
        ))
    }

    private func move(to target: SheetDetent) {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) {
            detent = target
            drag = 0
        }
    }
}

/// The sheet's measurements for one layout pass.
private struct SheetLayout {
    /// The sheet's own height: from where full stops to the bottom of the screen.
    let height: CGFloat
    /// How much shows at peek, tab bar included.
    let peek: CGFloat
    /// How much of the sheet's bottom the tab bar covers.
    let bottomInset: CGFloat
    /// The offset it rests at now.
    let rest: CGFloat
    /// The offset at peek, the furthest down it goes.
    let lowest: CGFloat

    init(height: CGFloat, peek: CGFloat, bottomInset: CGFloat, detent: SheetDetent) {
        self.height = height
        self.peek = peek
        self.bottomInset = bottomInset
        rest = detent.offset(in: height, peek: peek)
        lowest = SheetDetent.peek.offset(in: height, peek: peek)
    }
}
