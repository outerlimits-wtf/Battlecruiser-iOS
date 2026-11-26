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
    private let model: PubDetailModel
    private let context: PanelContext
    private let onClose: () -> Void
    private let onSelectPub: (PubSummary) -> Void
    @State private var tab: PanelTab = .overview
    @State private var toast: ToastMessage?
    @State private var isAddingPhoto = false
    @State private var reporting: ReportTarget?

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
        .sheet(isPresented: $isAddingPhoto) {
            if let id = model.selectedID {
                PhotoUploadSheet(pubID: id, context: context) { message in
                    toast = ToastMessage(message)
                    model.refresh()
                }
            }
        }
        .sheet(item: $reporting) { ReportSheet(target: $0, context: context) }
        .onChange(of: model.selectedID) { tab = .overview }
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
                    ReviewsTab(pubID: detail.id, reviews: detail.reviews, context: context, onChanged: changed)
                        .id(detail.id)
                }
            case .about:
                if let detail = model.detail {
                    AboutTab(detail: detail, onRemove: context.session.isSignedIn ? { removeFact($0, from: detail.id) } : nil)
                }
            }
        }
    }

    private func kindNote(_ summary: PubSummary) -> String? {
        guard let kind = summary.amenity.kind else { return nil }
        return context.meta?.venueKinds.first { $0.key == kind }?.note
    }

    private func factWriter(_ pubID: String) -> FactWriter? {
        guard context.session.isSignedIn else { return nil }
        return FactWriter(context: context, pubID: pubID, onChanged: changed) { toast = ToastMessage($0, tone: .bad) }
    }

    /// The Guinness price field's bounds, from `/meta`.
    private var priceBounds: ClosedRange<Int> {
        let field = context.meta?.contributableFields.first { $0.key == "guinness_price" }
        return (field?.min ?? 200)...(field?.max ?? 1500)
    }

    private func removeFact(_ contribution: Contribution, from pubID: String) {
        Task {
            do {
                changed(try await context.writer.deleteFact(contribution.id, from: pubID))
            } catch {
                if let message = PubDBError.wrapping(error)?.userMessage { toast = ToastMessage(message, tone: .bad) }
            }
        }
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
