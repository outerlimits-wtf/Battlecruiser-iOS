import SwiftUI
import DesignSystem

/// The round ✕ at the panel's top right.
struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Palette.ink)
                .frame(width: 36, height: 36)
                .background(Palette.surfaceSunken, in: Circle())
                .frame(width: Metrics.minTap, height: Metrics.minTap)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .padding(.trailing, Metrics.s)
        .accessibilityLabel("Close")
    }
}
