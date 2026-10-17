import SwiftUI

/// The map pin for a pub: always a ship (decision D17), with size, colour and
/// weight from its `PinEmphasis`.
///
/// Decorative to VoiceOver: the map annotation that holds it carries the pub's
/// name and open state as its label.
public struct ShipPin: View {
    /// Every pub on the map is a big boat.
    public static let emoji = "🚢"

    private let emphasis: PinEmphasis

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(emphasis: PinEmphasis) {
        self.emphasis = emphasis
    }

    public var body: some View {
        Text(Self.emoji)
            .font(.system(size: emphasis.diameter * 0.55))
            .frame(width: emphasis.diameter, height: emphasis.diameter)
            .background(Circle().fill(.background))
            .overlay(Circle().strokeBorder(emphasis.tint, lineWidth: ringWidth))
            .shadow(color: .black.opacity(isQuiet ? 0.1 : 0.25), radius: 2, y: 1)
            .grayscale(isQuiet ? 1 : 0)
            .opacity(isQuiet ? 0.6 : 1)
            .animation(reduceMotion ? nil : .snappy, value: emphasis)
            .accessibilityHidden(true)
    }

    private var isQuiet: Bool {
        emphasis == .closed
    }

    private var ringWidth: CGFloat {
        switch emphasis {
        case .open, .closingSoon:
            3
        case .unknown, .closed:
            1.5
        }
    }
}

#Preview("Every emphasis") {
    HStack(alignment: .bottom, spacing: 24) {
        ForEach(PinEmphasis.allCases, id: \.self) { emphasis in
            VStack(spacing: 8) {
                ShipPin(emphasis: emphasis)
                Text(String(describing: emphasis))
                    .font(.caption)
            }
        }
    }
    .padding()
}

#Preview("On a map-like background, dark") {
    HStack(spacing: 24) {
        ForEach(PinEmphasis.allCases, id: \.self) { emphasis in
            ShipPin(emphasis: emphasis)
        }
    }
    .padding(40)
    .background(Color.gray.opacity(0.3))
    .preferredColorScheme(.dark)
}
