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
                Button { query.minRating = step } label: {
                    Text("\(step)+ ") + Text(Image(systemName: "star.fill")).foregroundStyle(Palette.beerBright)
                }
                .buttonStyle(ChipStyle(isSelected: query.minRating == step))
                .accessibilityLabel("\(step) or more")
            }
            Button("Any") { query.minRating = nil }
                .buttonStyle(ChipStyle(isSelected: query.minRating == nil))
        }
    }
}
