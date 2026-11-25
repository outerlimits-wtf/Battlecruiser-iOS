import SwiftUI

/// The web's bottom sheet: over the map, above the tab bar, resting at peek,
/// half or full. Drag the top (grabber and header) to move it; flick to go one
/// step; tap the grabber to cycle. Changing `resetKey` (a new pub) lifts it
/// from peek to half so the new content is seen.
public struct BottomSheet<Header: View, Content: View>: View {
    @Binding private var detent: SheetDetent
    private let resetKey: AnyHashable?
    private let header: Header
    private let content: Content

    @GestureState private var drag: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The sheet's height, as a share of the space it sits in (the web's 88%).
    static var heightFraction: CGFloat { 0.88 }

    public init(
        detent: Binding<SheetDetent>,
        resetKey: AnyHashable? = nil,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        _detent = detent
        self.resetKey = resetKey
        self.header = header()
        self.content = content()
    }

    public var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height * Self.heightFraction
            let rest = detent.offset(in: height)
            let offset = min(max(rest + drag, 0), SheetDetent.peek.offset(in: height))

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    grabber
                    header
                }
                .contentShape(Rectangle())
                .gesture(dragGesture(height: height, rest: rest))
                content
                    .frame(maxHeight: .infinity, alignment: .top)
                    .opacity(detent == .peek && drag == 0 ? 0 : 1)
            }
            .frame(height: height)
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

    private var grabber: some View {
        Button {
            move(to: detent.next)
        } label: {
            Capsule()
                .fill(Palette.ink.opacity(0.25))
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
