import SwiftUI
import AppEnvironment
import DesignSystem

/// The top of the Me tab, as the web's menu: a sign-in card when signed out,
/// the person's card when signed in, nothing when the server has no sign-in.
public struct AccountBlock: View {
    private let session: SessionModel
    private let onOpenProfile: (String) -> Void

    public init(session: SessionModel, onOpenProfile: @escaping (String) -> Void) {
        self.session = session
        self.onOpenProfile = onOpenProfile
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Metrics.s) {
            if let user = session.user {
                SignedInCard(session: session, user: user, onOpenProfile: onOpenProfile)
            } else if session.offersSignIn {
                SignInCard(session: session)
            }
            if let message = session.message {
                Text(message).font(Typography.secondary).foregroundStyle(Palette.bad)
            }
        }
    }
}
