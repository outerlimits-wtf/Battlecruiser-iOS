import Foundation
import PubDBClient

/// Everything the app talks to, made once at launch and handed to the root.
/// Tests and previews make their own.
public struct AppDependencies: Sendable {
    public var client: PubDBClient

    public init(client: PubDBClient) {
        self.client = client
    }

    /// The real server, with the app's response cache.
    public static func live() -> AppDependencies {
        AppDependencies(client: .live())
    }

    /// Production without a disk cache, for previews.
    public static let preview = AppDependencies(client: PubDBClient())
}
