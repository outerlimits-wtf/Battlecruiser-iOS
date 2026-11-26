import SwiftUI
import DesignSystem

/// How the board is ranked, and what it left off, under the entries.
struct BoardNote: View {
    let note: String?
    let excluded: String?

    var body: some View {
        if note != nil || excluded != nil {
            VStack(alignment: .leading, spacing: Metrics.s) {
                if let note { Text(note) }
                if let excluded { Text(excluded) }
            }
            .font(Typography.secondary)
            .foregroundStyle(Palette.inkMuted)
            .padding(Metrics.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: Metrics.cardRadius))
        }
    }
}
