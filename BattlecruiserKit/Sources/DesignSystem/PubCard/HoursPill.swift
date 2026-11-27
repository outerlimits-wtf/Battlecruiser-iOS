import SwiftUI
import PubDBModels

/// The open state in words, coloured as the web does: green when open, amber
/// when closing soon, faint otherwise. The words carry the meaning.
public struct HoursPill: View {
    private let open: OpenInfo

    public init(_ open: OpenInfo) {
        self.open = open
    }

    public var body: some View {
        Text(text)
            .font(Typography.body.weight(.medium))
            .foregroundStyle(color)
    }

    private var text: String {
        if open.state == .unknown { return "Hours unknown" }
        if open.closingSoon, let countdown = open.countdownLabel { return "Closes in \(countdown)" }
        return open.label
    }

    private var color: Color {
        switch open.state {
        case .open: open.closingSoon ? Palette.warn : Palette.good
        case .closed, .unknown: Palette.inkFaint
        }
    }
}
