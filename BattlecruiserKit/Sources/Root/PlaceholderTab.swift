import SwiftUI
import DesignSystem

/// A tab whose screens are still to come (parity plan, Phase F).
struct PlaceholderTab: View {
    let emoji: String
    let title: String
    let message: String

    var body: some View {
        StateView(.empty(emoji: emoji, title: title, body: message))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.canvas)
    }
}
