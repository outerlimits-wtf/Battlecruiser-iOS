import Foundation
import Testing
import Auth
import PubDBClient
import PubDBModels
@testable import AppEnvironment

@MainActor
struct SessionModelTests {
    private static func me(_ username: String?) -> Me {
        let user = username.map {
            #"{"id":"u1","username":"\#($0)","label":"@\#($0)","usernameChosen":true,"contributions":0,"admin":false}"#
        } ?? "null"
        return try! JSONDecoder().decode(Me.self, from: Data(#"{"authRequired":true,"user":\#(user)}"#.utf8))
    }

    private static let invalidBearer = try! JSONDecoder().decode(
        Me.self, from: Data(#"{"authRequired":true,"user":null,"session":{"why":"invalid-bearer"}}"#.utf8)
    )

    @Test func aRefusedTokenIsRefreshedOnceThenAskedAgain() async {
        let source = FakeSession([Self.invalidBearer, Self.me("goatloaf")])
        let auth = FakeAuth(refreshes: "new")
        let model = SessionModel(source: source, auth: auth)

        await model.load()

        #expect(model.user?.label == "@goatloaf")
        #expect(auth.refreshCount == 1)
    }

    @Test func signingInFinishesWithTheRedirectThenLoadsWhoItIs() async {
        let source = FakeSession([Self.me("goatloaf")])
        let auth = FakeAuth(refreshes: nil)
        let model = SessionModel(source: source, auth: auth)

        await model.signIn { url, scheme in
            #expect(scheme == "wtf.outerlimits.battlecruiser")
            return URL(string: "wtf.outerlimits.battlecruiser:/auth/callback?code=c")!
        }

        #expect(auth.finished?.absoluteString.contains("code=c") == true)
        #expect(model.isSignedIn)
        #expect(model.message == nil)
    }

    @Test func cancellingTheSheetSaysNothing() async {
        let model = SessionModel(source: FakeSession([]), auth: FakeAuth(refreshes: nil))

        await model.signIn { _, _ in throw AuthError.cancelled }

        #expect(model.message == nil)
        #expect(!model.isWorking)
    }

    @Test func aTakenHandleShowsTheServersReason() async {
        let source = FakeSession([], renameError: PubDBError.server(status: 409, APIErrorDetail(code: "duplicate_value", message: "@x is taken. Try another.")))
        let model = SessionModel(source: source, auth: FakeAuth(refreshes: nil))

        let renamed = await model.rename(to: "x")

        #expect(!renamed)
        #expect(model.message == "@x is taken. Try another.")
    }
}

private final class FakeSession: SessionSource, @unchecked Sendable {
    private let lock = NSLock()
    private var answers: [Me]
    private let renameError: (any Error)?

    init(_ answers: [Me], renameError: (any Error)? = nil) {
        self.answers = answers
        self.renameError = renameError
    }

    func fetchMe() async throws -> Me {
        try lock.withLock {
            guard !answers.isEmpty else { throw URLError(.notConnectedToInternet) }
            return answers.removeFirst()
        }
    }

    func rename(to username: String) async throws -> Me {
        if let renameError { throw renameError }
        return try await fetchMe()
    }

    func deleteAccount() async throws -> AccountDeletion { throw URLError(.unsupportedURL) }
    func uploadAvatar(_ image: MultipartForm.File) async throws -> AvatarChange { throw URLError(.unsupportedURL) }
    func removeAvatar() async throws -> AvatarChange { throw URLError(.unsupportedURL) }
}

private final class FakeAuth: Authenticator, @unchecked Sendable {
    let isConfigured = true
    private let refreshed: String?
    private(set) var refreshCount = 0
    private(set) var finished: URL?
    private let real = AuthSession(configuration: AuthConfiguration(clientID: "c"), store: InMemoryTokenStore())

    init(refreshes: String?) {
        refreshed = refreshes
    }

    func beginSignIn() async throws -> SignInAttempt {
        try await real.beginSignIn()
    }

    func finishSignIn(callback: URL) async throws {
        finished = callback
    }

    func signOut() async {}

    func refreshedAccessToken() async -> String? {
        refreshCount += 1
        return refreshed
    }
}
