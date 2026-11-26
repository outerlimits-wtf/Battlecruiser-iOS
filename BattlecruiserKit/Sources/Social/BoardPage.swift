import SwiftUI
import AppEnvironment
import DesignSystem
import PubDBClient
import PubDBModels

/// One board, in the server's order, with its note and what was left off.
struct BoardPage: View {
    let info: BoardInfo
    let onOpenPub: (PubLink) -> Void
    @State private var remote: RemoteValue<Board>

    init(source: any CommunitySource, info: BoardInfo, location: Coordinate?, onOpenPub: @escaping (PubLink) -> Void) {
        self.info = info
        self.onOpenPub = onOpenPub
        _remote = State(initialValue: RemoteValue { try await source.fetchBoard(info.key, near: location) })
    }

    var body: some View {
        LoadableContent(remote: remote) { board in
            if board.entries.isEmpty {
                StateView(.empty(emoji: board.board.emoji, title: board.empty.title, body: board.empty.body))
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(board.entries) { entry in
                        Button { onOpenPub(PubLink(id: entry.pub.id, name: entry.pub.name)) } label: {
                            BoardRow(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                    BoardNote(note: board.board.note, excluded: board.excluded?.reason).padding(Metrics.l)
                }
            }
        }
        .navigationTitle(info.title)
    }
}
