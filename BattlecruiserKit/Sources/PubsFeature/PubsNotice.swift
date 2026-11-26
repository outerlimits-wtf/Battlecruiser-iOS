import PubDBClient

/// The one thing worth telling the user about the pubs on screen, if anything.
/// The map's banner and the list's empty state both come from this, so they
/// never disagree.
///
/// There is no "outside the covered area" notice: the server's regions grow
/// (Brighton, Manchester…) and `/meta` doesn't list them, so a hard-coded box
/// was wrong as soon as a region loaded. An area is only empty when the
/// server says so.
public nonisolated enum PubsNotice: Equatable, Sendable {
    /// No connection; whatever is on screen is from earlier.
    case offline(message: String)
    /// The server could not be reached or answered with an error.
    case failed(message: String)
    /// A fresh fetch came back with no pubs in this area.
    case nothingHere

    /// Most important first: a failure, then emptiness.
    ///
    /// - Parameters:
    ///   - pubCount: How many pubs are on screen.
    ///   - hasFreshResult: Whether this session has fetched successfully (not just
    ///     shown the saved list).
    ///   - isLoading: Whether a fetch is under way.
    ///   - error: The last fetch's failure, if it failed.
    public static func current(
        pubCount: Int,
        hasFreshResult: Bool,
        isLoading: Bool,
        error: PubDBError?
    ) -> PubsNotice? {
        if let error {
            return error.isOffline ? .offline(message: error.userMessage) : .failed(message: error.userMessage)
        }
        if hasFreshResult && !isLoading && pubCount == 0 {
            return .nothingHere
        }
        return nil
    }

    /// What to say, for the banner and the list's empty state.
    public var message: String {
        switch self {
        case .offline(let message), .failed(let message):
            message
        case .nothingHere:
            "No pubs here. Not everywhere's covered yet: try moving or zooming out the map."
        }
    }

    public var systemImage: String {
        switch self {
        case .offline:
            "wifi.slash"
        case .failed:
            "exclamationmark.triangle"
        case .nothingHere:
            "magnifyingglass"
        }
    }
}
