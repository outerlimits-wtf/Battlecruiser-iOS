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
    private let context: PanelContext
    private let onClose: () -> Void
    private let onSelectPub: (PubSummary) -> Void
    @State private var tab: PanelTab = .overview
    @State private var toast: ToastMessage?

    public init(
        model: PubDetailModel,
        context: PanelContext,
        onClose: @escaping () -> Void,
        onSelectPub: @escaping (PubSummary) -> Void
    ) {
        self.model = model
        self.context = context
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
                        ActionsRow(summary: summary, context: context)
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
        .toast($toast)
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
                    ReviewsTab(pubID: detail.id, reviews: detail.reviews, context: context, onChanged: changed)
                        .id(detail.id)
                }
            case .about:
                if let detail = model.detail {
                    AboutTab(detail: detail)
                }
            }
        }
    }

    private func kindNote(_ summary: PubSummary) -> String? {
        guard let kind = summary.amenity.kind else { return nil }
        return context.meta?.venueKinds.first { $0.key == kind }?.note
    }

    /// After a write: say so, and show what the server now has. A change held
    /// for an admin shows the server's message and changes nothing yet.
    private func changed(_ result: WriteResult) {
        if result.queued {
            toast = ToastMessage(result.message ?? "Sent to an admin to check.")
            return
        }
        toast = ToastMessage(result.message ?? "Saved. The next person through the door gets that.")
        if let id = model.selectedID { context.marks.noteVisited(id) }
        model.refresh()
        Task { await context.session.load() }
    }
}
