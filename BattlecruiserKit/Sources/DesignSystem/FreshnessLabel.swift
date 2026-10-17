import SwiftUI

/// "As of 22:41": shown when what's on screen is old enough that open states
/// may have changed. The 1am user's worst outcome is walking to a pub the app
/// said was open, so the app says how old its answer is.
public struct FreshnessLabel: View {
    private let fetchedAt: Date

    public init(fetchedAt: Date) {
        self.fetchedAt = fetchedAt
    }

    public var body: some View {
        Label("As of \(time)", systemImage: "clock.arrow.circlepath")
            .font(.footnote)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.thinMaterial, in: Capsule())
            .accessibilityLabel("Showing pubs as of \(time)")
    }

    /// The device's own time and format: this is about when the phone last
    /// heard from the server, not a time from the server.
    private var time: String {
        fetchedAt.formatted(date: .omitted, time: .shortened)
    }
}

#Preview {
    FreshnessLabel(fetchedAt: .now.addingTimeInterval(-20 * 60))
        .padding()
}
