import SwiftUI
import DesignSystem
import PubDBClient
import PubDBModels

/// The pubs in the map's area, as the web's results list: cards, with
/// skeletons, an error or an empty state in their place when there are none.
struct ResultsList: View {
    let pubs: PubsModel
    let selectedID: String?
    let onGoToLondon: () -> Void
    let onSelect: (PubSummary) -> Void
    /// Nil when already searching everywhere.
    let onSearchEverywhere: (() -> Void)?
    /// Nil when bars are already included.
    let onIncludeBars: (() -> Void)?
    /// Nil when no filters are set.
    let onClearFilters: (() -> Void)?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if let notice = pubs.notice, !pubs.pubs.isEmpty {
                    NoticeBanner(notice: notice, onGoToLondon: onGoToLondon, onRetry: pubs.refresh)
                        .padding(Metrics.m)
                }
                if pubs.pubs.isEmpty {
                    placeholder
                } else {
                    ForEach(pubs.pubs) { pub in
                        Button { onSelect(pub) } label: {
                            PubCard(pub, isSelected: pub.id == selectedID)
                        }
                        .buttonStyle(.plain)
                    }
                    ResultsFooter(count: pubs.pubs.count)
                }
            }
            .padding(.bottom, 120)
        }
        .refreshable {
            pubs.refresh()
            await pubs.loadTask?.value
        }
    }

    private var emptyMessage: String {
        pubs.query.activeFilterCount > 0
            ? "Nothing round here fits all that. Have you considered lowering your standards?"
            : "No pubs round here. Bleak, frankly."
    }

    @ViewBuilder
    private var placeholder: some View {
        if let notice = pubs.notice, notice != .nothingHere {
            StateView(.empty(emoji: "🍺", title: notice.message, body: nil)) {
                NoticeActions(notice: notice, onGoToLondon: onGoToLondon, onRetry: pubs.refresh)
            }
        } else if pubs.isLoading || pubs.fetchedAt == nil {
            StateView(.loading())
                .padding(.top, Metrics.s)
        } else {
            StateView(.empty(emoji: "🍺", title: "Nothing doing", body: emptyMessage)) {
                if let onIncludeBars {
                    Button("🍸 Include bars", action: onIncludeBars).buttonStyle(ChipStyle())
                }
                if let onClearFilters {
                    Button("Clear all filters", action: onClearFilters).buttonStyle(ChipStyle())
                }
                if let onSearchEverywhere {
                    Button("🌍 Search everywhere", action: onSearchEverywhere)
                        .buttonStyle(ChipStyle())
                }
            }
        }
    }
}
