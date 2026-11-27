import Foundation
import Observation
import Auth
import PubDBClient
import PubDBModels

/// Who is signed in, for every screen: loaded from `/me` on launch and on
/// resume, and changed by signing in, renaming, signing out or deleting.
@Observable
public final class SessionModel {
    /// The last `/me`. Nil until the first answer.
    public private(set) var me: Me?
    public private(set) var isWorking = false
    /// A line to show after something failed; cleared by the next attempt.
    public private(set) var message: String?

    public var user: MeUser? { me?.user }
    public var isSignedIn: Bool { user != nil }
    /// Whether to offer signing in: this build can, and the server has it.
    public var offersSignIn: Bool { auth.isConfigured && (me?.authRequired ?? true) }

    @ObservationIgnored private let source: any SessionSource
    @ObservationIgnored private let auth: any Authenticator
    /// Runs before the tokens go on sign-out (unregistering the phone for pushes).
    @ObservationIgnored public var beforeSignOut: () async -> Void = {}

    public init(source: any SessionSource, auth: any Authenticator) {
        self.source = source
        self.auth = auth
    }

    /// Ask who is signed in. A token the server no longer takes is refreshed
    /// once, then asked again (spec: `/me` answers 200 with "invalid-bearer").
    public func load() async {
        do {
            var answer = try await source.fetchMe()
            if answer.isInvalidBearer, await auth.refreshedAccessToken() != nil {
                answer = try await source.fetchMe()
            }
            me = answer
        } catch {
            // Keep whatever was known; a failed /me changes nothing on screen.
        }
    }

    /// Sign in through the system sheet. `authenticate` opens the URL and
    /// returns where WorkOS redirected (SwiftUI's web authentication session).
    public func signIn(authenticate: @escaping (URL, String) async throws -> URL) async {
        await work {
            let attempt = try await self.auth.beginSignIn()
            let callback = try await authenticate(attempt.url, attempt.callbackScheme)
            try await self.auth.finishSignIn(callback: callback)
            await self.load()
        }
    }

    public func signOut() async {
        await beforeSignOut()
        await auth.signOut()
        me = me.map { Me(authRequired: $0.authRequired, user: nil, session: nil) }
        await load()
    }

    /// Change the handle; true when it took. The server's reason shows otherwise.
    @discardableResult
    public func rename(to username: String) async -> Bool {
        await work { self.me = try await self.source.rename(to: username) }
    }

    /// Delete the account, then sign out; true when it went.
    @discardableResult
    public func deleteAccount() async -> Bool {
        await work {
            _ = try await self.source.deleteAccount()
            await self.signOut()
        }
    }

    @discardableResult
    public func setAvatar(_ image: MultipartForm.File) async -> Bool {
        await work {
            _ = try await self.source.uploadAvatar(image)
            await self.load()
        }
    }

    @discardableResult
    public func removeAvatar() async -> Bool {
        await work {
            _ = try await self.source.removeAvatar()
            await self.load()
        }
    }

    /// Runs one account action with the busy flag and the message handled.
    private func work(_ action: @escaping () async throws -> Void) async -> Bool {
        isWorking = true
        message = nil
        defer { isWorking = false }
        do {
            try await action()
            return true
        } catch let error as AuthError {
            message = error.userMessage
        } catch {
            message = PubDBError.wrapping(error)?.userMessage
        }
        return false
    }
}
