import SwiftUI
import DesignSystem
import PubDBModels

/// The About tab: the pub's names over the years, its listing, everything
/// else OpenStreetMap knows, and where all of it came from.
struct AboutTab: View {
    let detail: PubDetail
    /// Signed in: the facts people added, with ✕ on your own.
    var onRemove: ((Contribution) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.xl) {
            if let description = detail.description, !description.isEmpty {
                Text(description).font(Typography.body).foregroundStyle(Palette.ink)
            }
            HistoryTimeline(timeline: detail.timeline)
            if let heritage = detail.heritage {
                ListingCard(heritage: heritage)
            }
            if let onRemove {
                AddedByDrinkers(contributions: detail.contributions, onRemove: onRemove)
            }
            EverythingElse(tags: detail.osmTags)
            AboutFooter(sources: detail.sources, id: detail.id)
        }
    }
}
