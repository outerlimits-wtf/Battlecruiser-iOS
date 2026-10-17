import SwiftUI
import PubDBModels

/// The pubs in the map's current area as a list (decision D18): the same pubs,
/// the same order (open, unknown, closed, each nearest first).
struct PubListView: View {
    let pubs: [PubSummary]
    let openCount: Int
    /// Shown as the empty state, or above the rows when there are pubs.
    let notice: PubsNotice?
    let onGoToLondon: () -> Void
    let onRetry: () -> Void
    let onSelect: (PubSummary) -> Void
    let onRefresh: () async -> Void

    var body: some View {
        Group {
            if pubs.isEmpty {
                emptyState
            } else {
                List {
                    if let notice {
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(notice.message, systemImage: notice.systemImage)
                                    .font(.footnote)
                                NoticeActions(notice: notice, onGoToLondon: onGoToLondon, onRetry: onRetry)
                            }
                        }
                    }
                    Section {
                        ForEach(pubs) { pub in
                            Button {
                                onSelect(pub)
                            } label: {
                                PubRow(pub: pub)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text(summary)
                    } footer: {
                        // A licence condition wherever OSM data is shown (ODbL).
                        Text("Pub data © OpenStreetMap contributors")
                            .font(.caption2)
                    }
                }
                .listStyle(.plain)
            }
        }
        .refreshable {
            await onRefresh()
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if let notice {
            ContentUnavailableView {
                Label(notice.message, systemImage: notice.systemImage)
            } actions: {
                NoticeActions(notice: notice, onGoToLondon: onGoToLondon, onRetry: onRetry)
            }
        } else {
            // Empty with nothing to explain: the first fetch is still on its way.
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// "12 open of 35 here".
    private var summary: String {
        "\(openCount) open of \(pubs.count) here"
    }
}
