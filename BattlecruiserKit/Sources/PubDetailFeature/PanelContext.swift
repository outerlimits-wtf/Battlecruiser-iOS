import SwiftUI
import AppEnvironment
import PubDBModels

/// What the panel needs beyond the pub: who is signed in, their lists, the
/// server's lists, and how to write. Handed down from the root.
public struct PanelContext {
    public let session: SessionModel
    public let marks: MarksModel
    public let meta: Meta?
    public let writer: any PubWriteSource

    public init(session: SessionModel, marks: MarksModel, meta: Meta?, writer: any PubWriteSource) {
        self.session = session
        self.marks = marks
        self.meta = meta
        self.writer = writer
    }

    /// Signed out on a server that has sign-in: writes become "sign in" prompts.
    var mustSignIn: Bool { !session.isSignedIn }
}
