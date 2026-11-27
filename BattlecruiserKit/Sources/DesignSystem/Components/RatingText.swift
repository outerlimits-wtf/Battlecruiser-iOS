import SwiftUI

/// A pub's rating as the web draws it: the score, an amber star, then how many
/// reviews, "8.4 ★ (11)". The star's colour is decoration only; VoiceOver
/// hears "Rated 8.4, 11 reviews".
public enum RatingText {
    /// The score alone, to one decimal place: "8.4".
    /// S7 asks the server for a ready-made `ratingLabel`.
    static func score(_ rating: Double) -> String {
        rating.formatted(.number.precision(.fractionLength(1)))
    }

    public static func text(_ rating: Double, reviewCount: Int) -> Text {
        let spoken = "Rated \(score(rating)), \(reviewCount) \(reviewCount == 1 ? "review" : "reviews")"
        return (
            Text(score(rating) + " ")
            + Text("★").foregroundStyle(Palette.beerBright)
            + Text(" (\(reviewCount))")
        )
        .accessibilityLabel(spoken)
    }
}
