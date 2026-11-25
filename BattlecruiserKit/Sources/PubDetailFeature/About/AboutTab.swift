import SwiftUI
import DesignSystem
import PubDBModels

/// The About tab: the pub's names over the years, its listing, everything
/// else OpenStreetMap knows, and where all of it came from.
struct AboutTab: View {
    let detail: PubDetail

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.xl) {
            if let description = detail.description, !description.isEmpty {
                Text(description).font(Typography.body).foregroundStyle(Palette.ink)
            }
            HistoryTimeline(timeline: detail.timeline)
            if let heritage = detail.heritage {
                ListingCard(heritage: heritage)
            }
            EverythingElse(tags: detail.osmTags)
            AboutFooter(sources: detail.sources, id: detail.id)
        }
    }
}
