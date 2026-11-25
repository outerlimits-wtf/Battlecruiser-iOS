import SwiftUI
import PubDBModels

struct ReviewRow: View {
    let review: Review

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            metaLayout {
                Label("\(review.rating)/10", systemImage: "star")
                    .font(.subheadline.weight(.semibold))
                Text("\(review.attribution.label) · \(review.createdAtLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let text = review.text {
                Text(text)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
    }

    /// Score and byline side by side, or stacked at accessibility text sizes.
    private var metaLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
    }

    /// "Rated 5 out of 10 by @goatloaf, 11 Sept 2026. How u kicking me in at 10"
    private var spokenLabel: String {
        let heading = "Rated \(review.rating) out of 10 by \(review.attribution.label), \(review.createdAtLabel)."
        guard let text = review.text else {
            return heading
        }
        return "\(heading) \(text)"
    }
}
