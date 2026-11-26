import SwiftUI
import AppEnvironment
import DesignSystem
import PubDBClient
import PubDBModels

/// One list's pubs as cards; Been here starts with the coverage card.
struct SavedPubsList: View {
    let remote: RemoteValue<SavedPubs>
    let list: SavedList
    let onOpenPub: (String, String) -> Void

    var body: some View {
        ScrollView {
            if let saved = remote.value {
                LazyVStack(spacing: 0) {
                    if let coverage = saved.coverage, list == .visited {
                        CoverageCard(coverage).padding(Metrics.l)
                    }
                    if saved.pubs.isEmpty {
                        empty
                    }
                    ForEach(saved.pubs) { pub in
                        Button { onOpenPub(pub.id, pub.name) } label: { PubCard(pub) }
                            .buttonStyle(.plain)
                    }
                }
            } else if let error = remote.state.error {
                StateView(.error(message: error.userMessage, retry: { Task { await remote.load() } }))
            } else {
                StateView(.loading())
            }
        }
        .task { if remote.value == nil { await remote.load() } }
        .refreshable { await remote.load() }
    }

    private var empty: some View {
        list == .watchlist
            ? StateView(.empty(emoji: "⭐", title: "Nothing on the list", body: "Open a pub and tap Save. They pile up here, open ones first."))
            : StateView(.empty(emoji: "✅", title: "Nowhere ticked off yet", body: "Open a pub you have drunk in and tap Been here."))
    }
}
