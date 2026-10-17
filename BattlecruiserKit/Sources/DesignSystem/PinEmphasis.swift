import Foundation
import PubDBModels

/// How loudly a pub's pin speaks, decided only from what the server sent
/// (decision D12): open is loud, unknown is neutral, closed is quiet.
public nonisolated enum PinEmphasis: Hashable, Sendable, CaseIterable {
    /// Open now.
    case open
    /// Open, but within an hour of closing.
    case closingSoon
    /// No hours on record. Never drawn as open or as closed.
    case unknown
    /// Closed now, or not trading at all.
    case closed

    public init(state: OpenState, serving: Bool, closingSoon: Bool) {
        // A pub that is shut down or shut for a refit is never "open", whatever
        // its last known hours say.
        guard serving else {
            self = .closed
            return
        }
        switch state {
        case .open:
            self = closingSoon ? .closingSoon : .open
        case .unknown:
            self = .unknown
        case .closed:
            self = .closed
        }
    }

    public init(_ pub: PubSummary) {
        self.init(state: pub.open.state, serving: pub.status.serving, closingSoon: pub.open.closingSoon)
    }

    /// Pins with a higher order are drawn on top, so open pubs are never hidden
    /// under closed ones.
    public var drawOrder: Int {
        switch self {
        case .open, .closingSoon:
            2
        case .unknown:
            1
        case .closed:
            0
        }
    }

    /// The pin's size in points.
    public var diameter: CGFloat {
        switch self {
        case .open, .closingSoon:
            40
        case .unknown:
            32
        case .closed:
            24
        }
    }
}
