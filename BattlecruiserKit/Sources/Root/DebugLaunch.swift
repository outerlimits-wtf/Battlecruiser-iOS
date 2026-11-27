import Foundation

/// Launch arguments for looking at a screen without tapping to it, e.g.
/// `-openPub node/251526423` from a scheme or `simctl launch`. Debug builds only.
enum DebugLaunch {
    /// The pub id after `-openPub`, if given.
    static var pubToOpen: String? {
        value(after: "-openPub")
    }

    /// The tab after `-tab` (map, social, lists, me), if given.
    static var tab: RootTab? {
        value(after: "-tab").flatMap(RootTab.init(rawValue:))
    }

    private static func value(after flag: String) -> String? {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
        #else
        return nil
        #endif
    }
}
