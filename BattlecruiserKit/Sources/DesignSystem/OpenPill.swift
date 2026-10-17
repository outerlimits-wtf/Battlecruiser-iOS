import SwiftUI
import PubDBModels

/// "Closes 23:00", "Closed", "Hours unknown": the server's label with a dot in
/// the pub's open-state colour. The text carries the meaning; the colour only
/// reinforces it, so it reads the same without colour vision.
public struct OpenPill: View {
    private let label: String
    private let emphasis: PinEmphasis

    public init(pub: PubSummary) {
        label = pub.open.label
        emphasis = PinEmphasis(pub)
    }

    public init(label: String, emphasis: PinEmphasis) {
        self.label = label
        self.emphasis = emphasis
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(emphasis.tint)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(emphasis.tint.opacity(0.15), in: Capsule())
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        OpenPill(label: "Closes 23:00", emphasis: .open)
        OpenPill(label: "Closes 23:00", emphasis: .closingSoon)
        OpenPill(label: "Hours unknown", emphasis: .unknown)
        OpenPill(label: "Closed", emphasis: .closed)
    }
    .padding()
}
