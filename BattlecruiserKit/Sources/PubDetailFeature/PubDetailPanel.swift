import SwiftUI
import DesignSystem
import PubDBClient
import PubDBModels

/// One pub in full, in the bottom sheet over the map, laid out as the web's
/// panel: photos, name and status, actions, then Overview, Reviews and About.
///
/// The map stays usable behind it, so tapping another pin switches pubs
/// without closing anything. Draws from the summary straight away and fills
/// in the rest when the detail arrives.
public struct PubDetailPanel: View {
    let model: PubDetailModel
    let context: PanelContext
    private let onClose: () -> Void
    private let onSelectPub: (PubSummary) -> Void
    @State var tab: PanelTab = .overview
    @State var toast: ToastMessage?
    @State var isAddingPhoto = false
    @State var reporting: ReportTarget?
    /// The review the quote asked for, brought into view on the Reviews tab.
    @State var focusReview: Int?
    /// Fix mode: the Fix panel in place of the tabs.
    @State var isFixing = false

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
        ScrollViewReader { scroller in
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                if let summary = model.summary {
                    GalleryStrip(
                        photos: model.detail?.photos ?? summary.photo.map { [$0] } ?? [],
                        name: summary.name,
                        emoji: summary.amenity.symbol.emoji,
                        onAdd: context.session.isSignedIn ? { isAddingPhoto = true } : nil,
                        onReport: context.session.isSignedIn ? { photo in
                            reporting = photo.id.map { ReportTarget(type: "photo", id: $0) }
                        } : nil
                    )
                    VStack(alignment: .leading, spacing: Metrics.l) {
                        if let savedAt = model.showingCachedFrom {
                            FreshnessLabel(fetchedAt: savedAt)
                        }
                        PanelHeader(summary: summary, city: model.detail?.city, kindNote: kindNote(summary))
                        ActionsRow(
                            summary: summary,
                            context: context,
                            isFixing: context.session.isSignedIn && model.detail != nil ? $isFixing : nil
                        )
                        // Above the tabs, so it shows whichever tab is open.
                        if let quote = summary.quote {
                            QuoteCard(
                                quote: quote,
                                review: model.detail?.reviews.first { $0.id == quote.reviewId },
                                reviewCount: summary.reviewCount,
                                maxRating: context.meta?.limits.maxRating ?? 10,
                                onOpenReview: { openReviews(at: $0) },
                                onOpenReviews: { openReviews(at: nil) }
                            )
                        }
                    }
                    .padding(Metrics.l)
                    if isFixing, let detail = model.detail, let writer = factWriter(detail.id) {
                        PanelStatus(model: model)
                        FixPanel(
                            layout: FixLayout(fields: context.meta?.contributableFields ?? [], editable: detail.editable),
                            venueKinds: context.meta?.venueKinds ?? [],
                            writer: writer
                        )
                        .padding(Metrics.l)
                    } else {
                        Section {
                            PanelStatus(model: model)
                            tabContent(summary)
                                .padding(Metrics.l)
                        } header: {
                            PanelTabBar(selection: $tab, reviewCount: model.detail?.reviews.count ?? summary.reviewCount)
                        }
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
        .sheetScrollable()
        .onChange(of: focusReview) { _, id in
            guard let id else { return }
            Task {
                try? await Task.sleep(for: .milliseconds(150))
                withAnimation { scroller.scrollTo(ReviewsTab.anchor(id), anchor: .top) }
            }
        }
        }
        .overlay(alignment: .topTrailing) {
            CloseButton(action: onClose).padding(.top, Metrics.s)
        }
        .toast($toast)
        .sheet(isPresented: $isAddingPhoto) {
            if let id = model.selectedID {
                PhotoUploadSheet(pubID: id, context: context) { message in
                    toast = ToastMessage(message)
                    model.refresh()
                }
            }
        }
        .sheet(item: $reporting) { ReportSheet(target: $0, context: context) }
        .onChange(of: model.selectedID) {
            tab = .overview
            focusReview = nil
            isFixing = false
        }
        .onChange(of: context.session.isSignedIn) { _, signedIn in
            if !signedIn { isFixing = false }
        }
    }

    @ViewBuilder
    private func tabContent(_ summary: PubSummary) -> some View {
        VStack(alignment: .leading, spacing: Metrics.xl) {
            switch tab {
            case .overview:
                OverviewTab(
                    summary: summary,
                    detail: model.detail,
                    nearby: model.similar,
                    onSelectPub: onSelectPub,
                    writer: factWriter(summary.id),
                    priceBounds: priceBounds
                )
            case .reviews:
                if let detail = model.detail {
                    ReviewsTab(pubID: detail.id, reviews: detail.reviews, context: context, focusID: focusReview, onChanged: changed)
                        .id(detail.id)
                }
            case .about:
                if let detail = model.detail {
                    AboutTab(detail: detail, onRemove: context.session.isSignedIn ? { removeFact($0, from: detail.id) } : nil)
                }
            }
        }
    }

    /// The Reviews tab, brought into view at one review or at the top.
    private func openReviews(at id: Int?) {
        focusReview = id
        tab = .reviews
    }

    private func kindNote(_ summary: PubSummary) -> String? {
        guard let kind = summary.amenity.kind else { return nil }
        return context.meta?.venueKinds.first { $0.key == kind }?.note
    }
}

