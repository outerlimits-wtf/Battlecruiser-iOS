import SwiftUI

/// An ⓘ that shows a short note when tapped, e.g. what "gastropub" means here.
public struct InfoTip: View {
    private let note: String
    @State private var isShowing = false

    public init(_ note: String) {
        self.note = note
    }

    public var body: some View {
        Button {
            isShowing = true
        } label: {
            Image(systemName: "info.circle")
                .font(Typography.secondary)
                .foregroundStyle(Palette.inkFaint)
                .frame(minWidth: Metrics.minTap, minHeight: Metrics.minTap)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("About this")
        .accessibilityHint(note)
        .popover(isPresented: $isShowing) {
            Text(note)
                .font(Typography.body)
                .padding(Metrics.l)
                .frame(idealWidth: 260)
                .presentationCompactAdaptation(.popover)
        }
    }
}

#Preview {
    HStack(spacing: 0) {
        Text("Gastropub")
        InfoTip("We mean pub-themed restaurants, not just a pub with a kitchen.")
    }
    .padding()
}
