import SwiftUI

/// The web's small-caps section heading: "WHAT'S THERE", "OPENING HOURS".
public struct SectionHeader: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text.uppercased())
            .font(Typography.sectionHeader)
            .tracking(0.9)
            .foregroundStyle(Palette.inkMuted)
            .accessibilityLabel(text)
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    SectionHeader("What's there").padding()
}
