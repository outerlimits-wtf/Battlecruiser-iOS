import Foundation

/// The person's two lists of pubs.
public enum SavedList: String, Sendable, CaseIterable {
    /// The hit list: pubs they mean to get to.
    case watchlist
    /// Been here: pubs they have drunk in.
    case visited

    var markPath: String {
        switch self {
        case .watchlist: "watch"
        case .visited: "visited"
        }
    }
}
