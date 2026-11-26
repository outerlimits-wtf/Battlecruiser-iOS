import SwiftUI
import AppEnvironment
import DesignSystem
import PubDBClient
import PubDBModels

/// The Lists tab: the hit list and Been here, as on the web. Signed out, an
/// invitation to sign in, since the lists follow the account.
public struct ListsScreen: View {
    private let source: any ListsSource
    private let isSignedIn: Bool
    private let onOpenPub: (String, String) -> Void
    @State private var list = SavedList.watchlist
    @State private var hitList: RemoteValue<SavedPubs>
    @State private var beenHere: RemoteValue<SavedPubs>

    public init(source: any ListsSource, isSignedIn: Bool, location: Coordinate?, onOpenPub: @escaping (String, String) -> Void) {
        self.source = source
        self.isSignedIn = isSignedIn
        self.onOpenPub = onOpenPub
        _hitList = State(initialValue: RemoteValue { try await source.fetchSaved(.watchlist, near: location) })
        _beenHere = State(initialValue: RemoteValue { try await source.fetchSaved(.visited, near: location) })
    }

    public var body: some View {
        NavigationStack {
            Group {
                if isSignedIn {
                    VStack(spacing: 0) {
                        Picker("List", selection: $list) {
                            Text("⭐ Hit list").tag(SavedList.watchlist)
                            Text("✅ Been here").tag(SavedList.visited)
                        }
                        .pickerStyle(.segmented)
                        .padding(Metrics.l)
                        SavedPubsList(remote: list == .watchlist ? hitList : beenHere, list: list, onOpenPub: onOpenPub)
                            .id(list)
                    }
                } else {
                    StateView(.empty(emoji: "⭐", title: "Sign in to keep a list",
                                     body: "It follows the account rather than the phone, so it's there on the web too. Sign in from the Me tab."))
                        .frame(maxHeight: .infinity)
                }
            }
            .background(Palette.canvas)
            .navigationTitle("Lists")
        }
    }
}
