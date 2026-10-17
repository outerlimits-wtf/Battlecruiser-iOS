import SwiftUI

extension PinEmphasis {
    /// The one colour for each open state, shared by pins, pills and rows so
    /// "open" looks the same everywhere.
    public var tint: Color {
        switch self {
        case .open:
            .green
        case .closingSoon:
            .orange
        case .unknown, .closed:
            .gray
        }
    }
}
