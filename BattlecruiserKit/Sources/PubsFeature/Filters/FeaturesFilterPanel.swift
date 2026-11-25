import SwiftUI
import DesignSystem
import PubDBClient
import PubDBModels

/// "WHAT YOU ARE AFTER": a chip per feature the server lists.
struct FeaturesFilterPanel: View {
    @Binding var query: PubQuery
    let features: [LabelledSymbol]

    var body: some View {
        SectionHeader("What you are after")
        ChipFlow {
            ForEach(features) { feature in
                Button {
                    if query.features.contains(feature.key) {
                        query.features.remove(feature.key)
                    } else {
                        query.features.insert(feature.key)
                    }
                } label: {
                    HStack(spacing: 4) {
                        SymbolGlyph(feature.symbol, size: 15)
                        Text(feature.label)
                    }
                }
                .buttonStyle(ChipStyle(isSelected: query.features.contains(feature.key)))
            }
        }
        if !query.features.isEmpty {
            Button("Clear features") { query.features = [] }
                .font(Typography.secondary)
                .foregroundStyle(Palette.beer)
        }
    }
}
