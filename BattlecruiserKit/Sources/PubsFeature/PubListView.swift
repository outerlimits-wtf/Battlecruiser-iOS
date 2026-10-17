import SwiftUI
import PubDBModels

/// The pubs in the map's current area as a list (decision D18): the same pubs,
/// the same order (open, unknown, closed, each nearest first).
struct PubListView: View {
    let pubs: [PubSummary]
    let openCount: Int
    let isLoading: Bool
    let onSelect: (PubSummary) -> Void
    let onRefresh: () async -> Void

    var body: some View {
        Group {
            if pubs.isEmpty && !isLoading {
                ContentUnavailableView(
                    "No pubs here",
                    systemImage: "map",
                    description: Text("Switch to the map and move it to find some.")
                )
            } else {
                List {
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

    /// "12 open of 35 here".
    private var summary: String {
        "\(openCount) open of \(pubs.count) here"
    }
}
