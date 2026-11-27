import AuthenticationServices
import SwiftUI
import AppEnvironment
import Auth
import DesignSystem

/// "🔑 Sign in. Reading is free. Adding needs a name."
struct SignInCard: View {
    let session: SessionModel
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession

    var body: some View {
        Button {
            Task {
                await session.signIn { url, scheme in
                    do {
                        return try await webAuthenticationSession.authenticate(
                            using: url,
                            callbackURLScheme: scheme,
                            preferredBrowserSession: .shared
                        )
                    } catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin {
                        throw AuthError.cancelled
                    }
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("🔑 Sign in").font(Typography.rowTitle)
                Text("Reading is free. Adding needs a name.").font(Typography.body).opacity(0.8)
            }
            .foregroundStyle(Palette.onInk)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Metrics.l)
            .background(Palette.ink, in: RoundedRectangle(cornerRadius: Metrics.cardRadius))
        }
        .buttonStyle(.plain)
        .disabled(session.isWorking)
        .accessibilityHint("Opens the sign-in page")
    }
}
