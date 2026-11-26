import SwiftUI

/// A wrapping row of chips.
public struct ChipFlow<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        // Lays chips out in rows, wrapping as needed.
        FlowLayout(spacing: Metrics.s) { content }
    }
}
