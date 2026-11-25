import SwiftUI
import DesignSystem
import PubDBClient

/// "RATED AT LEAST".
struct RatingFilterPanel: View {
    @Binding var query: PubQuery

    var body: some View {
        SectionHeader("Rated at least")
        ChipFlow {
            ForEach(FilterOptions.ratingSteps, id: \.self) { step in
                Button("⭐ \(step)+") { query.minRating = step }
                    .buttonStyle(ChipStyle(isSelected: query.minRating == step))
            }
            Button("Any") { query.minRating = nil }
                .buttonStyle(ChipStyle(isSelected: query.minRating == nil))
        }
    }
}
