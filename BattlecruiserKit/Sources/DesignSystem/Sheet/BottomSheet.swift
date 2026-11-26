import SwiftUI

/// The web's bottom sheet: over the map, above the tab bar, resting at peek,
/// half or full. Drag the top (grabber and header) to move it; flick to go one
/// step; tap the grabber to cycle. Changing `resetKey` (a new pub) lifts it
/// from peek to half so the new content is seen.
///
/// The content only scrolls at full: below it, a drag anywhere on the content
/// moves the sheet instead, so it always opens all the way before scrolling.
public struct BottomSheet<Header: View, Content: View>: View {
    @Binding private var detent: SheetDetent
    private let resetKey: AnyHashable?
    /// Draw the grabber over the content (a photo running to the top edge)
    /// rather than in a strip above it. The header is not shown.
    private let overlaysGrabber: Bool
    private let header: Header
    private let content: Content

    @GestureState private var drag: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The sheet's height, as a share of the space it sits in (the web's 88%).
    static var heightFraction: CGFloat { 0.88 }

    public init(
        detent: Binding<SheetDetent>,
        resetKey: AnyHashable? = nil,
        overlaysGrabber: Bool = false,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        _detent = detent
        self.resetKey = resetKey
        self.overlaysGrabber = overlaysGrabber
        self.header = header()
        self.content = content()
    }

    public var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height * Self.heightFraction
            let rest = detent.offset(in: height)
            let offset = min(max(rest + drag, 0), SheetDetent.peek.offset(in: height))

            Group {
                if overlaysGrabber {
                    ZStack(alignment: .top) {
                        sheetContent(height: height, rest: rest)
                        grabber(onPhoto: true)
                            .gesture(dragGesture(height: height, rest: rest))
                    }
                } else {
                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            grabber(onPhoto: false)
                            header
                        }
                        .contentShape(Rectangle())
                        .gesture(dragGesture(height: height, rest: rest))
                        sheetContent(height: height, rest: rest)
                    }
                }
            }
            .frame(height: height)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: Metrics.sheetRadius, topTrailingRadius: Metrics.sheetRadius))
            .background(
                UnevenRoundedRectangle(topLeadingRadius: Metrics.sheetRadius, topTrailingRadius: Metrics.sheetRadius)
                    .fill(Palette.surface)
                    .shadow(color: .black.opacity(0.24), radius: 14, y: -3)
            )
            .offset(y: proxy.size.height - height + offset)
        }
        .onChange(of: resetKey) {
            if detent == .peek { move(to: .half) }
        }
    }

    /// Scrolls only at full; below it, dragging the content moves the sheet.
    private func sheetContent(height: CGFloat, rest: CGFloat) -> some View {
        content
            .frame(maxHeight: .infinity, alignment: .top)
            .opacity(detent == .peek && drag == 0 ? 0 : 1)
            .scrollDisabled(detent != .full)
            .gesture(dragGesture(height: height, rest: rest), including: detent == .full ? .subviews : .all)
    }

    private func grabber(onPhoto: Bool) -> some View {
        Button {
            move(to: detent.next)
        } label: {
            Capsule()
                .fill(onPhoto ? Color.white.opacity(0.9) : Palette.ink.opacity(0.25))
                .shadow(color: .black.opacity(onPhoto ? 0.35 : 0), radius: 2)
                .frame(width: 44, height: 6)
                .frame(width: 112, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(detent.grabberLabel)
    }

    private func dragGesture(height: CGFloat, rest: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .updating($drag) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                move(to: SheetDetent.snap(
                    offset: rest + value.translation.height,
                    velocity: value.velocity.height,
                    height: height
                ))
            }
    }

    private func move(to target: SheetDetent) {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) {
            detent = target
        }
    }
}
