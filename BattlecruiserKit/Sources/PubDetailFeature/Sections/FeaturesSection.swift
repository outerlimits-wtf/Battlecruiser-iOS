import SwiftUI
import PubDBModels

/// What the pub has. Only "yes" answers are listed: "no" and "not sure" are
/// for the contribution screens that come later.
struct FeaturesSection: View {
    let features: [FeatureAnswer]

    var body: some View {
        let present = features.filter { $0.value == .yes }
        if !present.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle("Has")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), alignment: .leading)], alignment: .leading, spacing: 8) {
                    ForEach(present) { feature in
                        Text("\(feature.symbol.emoji) \(feature.label)")
                            .font(.subheadline)
                    }
                }
            }
        }
    }
}
