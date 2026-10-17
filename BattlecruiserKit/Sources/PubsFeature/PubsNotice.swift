import PubDBClient

/// The one thing worth telling the user about the pubs on screen, if anything.
/// The map's banner and the list's empty state both come from this, so they
/// never disagree.
public nonisolated enum PubsNotice: Equatable, Sendable {
    /// The map shows somewhere PubDB has no data for.
    case outsideCoverage
    /// No connection; whatever is on screen is from earlier.
    case offline(message: String)
    /// The server could not be reached or answered with an error.
    case failed(message: String)
    /// A fresh fetch came back with no pubs in this area.
    case nothingHere

    /// The only area PubDB has pubs for: its London region (docs/backend/01-big-picture.md,
    /// "How data gets in"). Other regions exist in the backend but are not loaded.
    public static let coverage = BoundingBox(west: -0.51, south: 51.28, east: 0.33, north: 51.69)

    /// Most important first: being outside the covered area explains everything
    /// else (an empty result, say), so it wins; then a failure; then emptiness.
    ///
    /// - Parameters:
    ///   - area: The area most recently asked for, if any.
    ///   - pubCount: How many pubs are on screen.
    ///   - hasFreshResult: Whether this session has fetched successfully (not just
    ///     shown the saved list).
    ///   - isLoading: Whether a fetch is under way.
    ///   - error: The last fetch's failure, if it failed.
    public static func current(
        area: BoundingBox?,
        pubCount: Int,
        hasFreshResult: Bool,
        isLoading: Bool,
        error: PubDBError?
    ) -> PubsNotice? {
        if let area, !coverage.intersects(area) {
            return .outsideCoverage
        }
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
        case .outsideCoverage:
            "Battlecruiser only knows London's pubs for now."
        case .offline(let message), .failed(let message):
            message
        case .nothingHere:
            "No pubs here. Try moving or zooming out the map."
        }
    }

    public var systemImage: String {
        switch self {
        case .outsideCoverage:
            "mappin.slash"
        case .offline:
            "wifi.slash"
        case .failed:
            "exclamationmark.triangle"
        case .nothingHere:
            "magnifyingglass"
        }
    }
}
