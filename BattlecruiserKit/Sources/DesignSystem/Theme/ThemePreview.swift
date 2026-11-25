import SwiftUI

/// Every token in one place, to check light and dark side by side.
struct ThemePreview: View {
    private let swatches: [(String, Color)] = [
        ("ink", Palette.ink), ("inkMuted", Palette.inkMuted), ("inkFaint", Palette.inkFaint),
        ("canvas", Palette.canvas), ("surface", Palette.surface), ("surfaceSunken", Palette.surfaceSunken),
        ("beer", Palette.beer), ("beerBright", Palette.beerBright), ("beerSoft", Palette.beerSoft),
        ("good", Palette.good), ("goodSoft", Palette.goodSoft), ("warn", Palette.warn),
        ("warnSoft", Palette.warnSoft), ("bad", Palette.bad), ("badSoft", Palette.badSoft),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.s) {
                ForEach(swatches, id: \.0) { name, color in
                    HStack {
                        RoundedRectangle(cornerRadius: Metrics.thumbRadius)
                            .fill(color)
                            .frame(width: 44, height: 28)
                            .overlay(RoundedRectangle(cornerRadius: Metrics.thumbRadius).stroke(Palette.surfaceSunken))
                        Text(name).font(Typography.body).foregroundStyle(Palette.ink)
                    }
                }
                HStack {
                    ForEach(PinState.allCases, id: \.self) { state in
                        Circle()
                            .fill(state.color.opacity(state.dotOpacity))
                            .frame(width: state.dotRadius * 2, height: state.dotRadius * 2)
                    }
                }
            }
            .padding(Metrics.l)
        }
        .background(Palette.canvas)
    }
}

#Preview("Light") { ThemePreview().preferredColorScheme(.light) }
#Preview("Dark") { ThemePreview().preferredColorScheme(.dark) }
