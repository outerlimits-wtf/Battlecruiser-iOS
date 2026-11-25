import SwiftUI
import DesignSystem

/// Shown instead of everything else when the server has retired this build
/// (`clients.ios.minVersion`). The spec asks for this and nothing else.
struct UpdateRequiredView: View {
    var body: some View {
        VStack(spacing: Metrics.l) {
            Text("🚢").font(.system(size: 64)).accessibilityHidden(true)
            Text("Time to update")
                .font(Typography.title)
                .foregroundStyle(Palette.ink)
            Text("This version of the app is too old to talk to PubDB any more. Update it to carry on.")
                .font(Typography.body)
                .foregroundStyle(Palette.inkMuted)
                .multilineTextAlignment(.center)
        }
        .padding(Metrics.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.canvas)
    }
}

#Preview {
    UpdateRequiredView()
}
