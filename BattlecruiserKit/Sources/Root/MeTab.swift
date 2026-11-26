import SwiftUI
import Account
import AppEnvironment
import DesignSystem

/// The Me tab: the account first. Appearance and About join it in F1.
struct MeTab: View {
    let session: SessionModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.xl) {
                    AccountBlock(session: session, onOpenProfile: { _ in })
                    if !session.isSignedIn && !session.offersSignIn {
                        StateView(.empty(emoji: "🍺", title: "Me", body: "Settings and About land here."))
                    }
                }
                .padding(Metrics.l)
            }
            .background(Palette.canvas)
            .navigationTitle("Me")
        }
    }
}
