import SwiftUI
import DesignSystem
import PubDBModels

/// One pub in full, in the bottom sheet over the map, laid out as the web's
/// panel: photos, name and status, actions, then Overview, Reviews and About.
///
/// The map stays usable behind it, so tapping another pin switches pubs
/// without closing anything. Draws from the summary straight away and fills
/// in the rest when the detail arrives.
public struct PubDetailPanel: View {
    private let model: PubDetailModel
    private let meta: Meta?
    private let onClose: () -> Void
    private let onSelectPub: (PubSummary) -> Void
    @State private var tab: PanelTab = .overview

    public init(
        model: PubDetailModel,
        meta: Meta?,
        onClose: @escaping () -> Void,
        onSelectPub: @escaping (PubSummary) -> Void
    ) {
        self.model = model
        self.meta = meta
        self.onClose = onClose
        self.onSelectPub = onSelectPub
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                if let summary = model.summary {
                    GalleryStrip(
                        photos: model.detail?.photos ?? summary.photo.map { [$0] } ?? [],
                        name: summary.name,
                        emoji: summary.amenity.symbol.emoji
                    )
                    VStack(alignment: .leading, spacing: Metrics.l) {
                        if let savedAt = model.showingCachedFrom {
                            FreshnessLabel(fetchedAt: savedAt)
                        }
                        PanelHeader(summary: summary, city: model.detail?.city, kindNote: kindNote(summary))
                        ActionsRow(summary: summary)
                    }
                    .padding(Metrics.l)
                    Section {
                        PanelStatus(model: model)
                        tabContent(summary)
                            .padding(Metrics.l)
                    } header: {
                        PanelTabBar(selection: $tab, reviewCount: model.detail?.reviews.count ?? summary.reviewCount)
                    }
                } else if let name = model.placeholderName {
                    // Chosen from a map pin: the name now, the rest on arrival.
                    Text(name)
                        .font(Typography.title)
                        .foregroundStyle(Palette.ink)
                        .accessibilityAddTraits(.isHeader)
                        .padding(Metrics.l)
                        .padding(.top, Metrics.xl)
                    PanelStatus(model: model)
                }
            }
            .padding(.bottom, 120)
        }
        .overlay(alignment: .topTrailing) {
            CloseButton(action: onClose).padding(.top, Metrics.s)
        }
        .onChange(of: model.selectedID) { tab = .overview }
    }

    @ViewBuilder
    private func tabContent(_ summary: PubSummary) -> some View {
        VStack(alignment: .leading, spacing: Metrics.xl) {
            switch tab {
            case .overview:
                OverviewTab(summary: summary, detail: model.detail, nearby: model.similar, onSelectPub: onSelectPub)
            case .reviews:
                if let detail = model.detail {
                    ReviewsSection(reviews: detail.reviews).id(detail.id)
                }
            case .about:
                if let detail = model.detail {
                    HistorySection(timeline: detail.timeline)
                }
            }
        }
    }

    private func kindNote(_ summary: PubSummary) -> String? {
        guard let kind = summary.amenity.kind else { return nil }
        return meta?.venueKinds.first { $0.key == kind }?.note
    }
}
