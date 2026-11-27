import SwiftUI
import AppEnvironment
import PubDBClient
import PubDBModels

/// What the panel needs beyond the pub: who is signed in, their lists, the
/// server's lists, and how to write. Handed down from the root.
public struct PanelContext {
    public let session: SessionModel
    public let marks: MarksModel
    public let meta: Meta?
    public let writer: any PubWriteSource
    /// Where the person is, sent with writes so the pub that comes back has
    /// its distance (S12).
    public let location: Coordinate?
    /// Show someone's profile (a reviewer's); nil where that can't be done.
    public let onOpenProfile: ((ProfileLink) -> Void)?

    public init(
        session: SessionModel,
        marks: MarksModel,
        meta: Meta?,
        writer: any PubWriteSource,
        location: Coordinate? = nil,
        onOpenProfile: ((ProfileLink) -> Void)? = nil
    ) {
        self.session = session
        self.marks = marks
        self.meta = meta
        self.writer = writer
        self.location = location
        self.onOpenProfile = onOpenProfile
    }

    /// Signed out on a server that has sign-in: writes become "sign in" prompts.
    var mustSignIn: Bool { !session.isSignedIn }
}
