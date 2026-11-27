import SwiftUI
import UIKit
import PubDBModels

/// Draws a server `Symbol` the way the spec says to ("Symbols, concretely"):
/// bundled artwork for its `key` if the app has it; else the image at `url`,
/// showing the emoji until it arrives and if it fails; else the emoji. Never
/// waits on the network to draw something.
public struct SymbolGlyph: View {
    private let symbol: Symbol
    private let size: CGFloat

    public init(_ symbol: Symbol, size: CGFloat = 17) {
        self.symbol = symbol
        self.size = size
    }

    public var body: some View {
        Group {
            if let bundled = UIImage(named: symbol.key) {
                Image(uiImage: bundled).resizable().scaledToFit()
            } else if let url = symbol.url.flatMap(URL.init(string:)) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else {
                        emoji
                    }
                }
            } else {
                emoji
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var emoji: some View {
        Text(symbol.emoji)
            .font(.system(size: size * 0.85))
            .minimumScaleFactor(0.5)
    }
}
