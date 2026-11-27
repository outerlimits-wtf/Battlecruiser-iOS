import Foundation
import PubDBModels

extension AppVersion {
    /// This build's `CFBundleShortVersionString`, or nil if it has none.
    public static func current(in bundle: Bundle = .main) -> AppVersion? {
        (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String).flatMap(AppVersion.init)
    }
}
