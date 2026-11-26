import Foundation

/// The last `ETag` seen for each request, so the next one can ask "has this
/// changed?" with `If-None-Match`. In memory only: a fresh launch fetches in full.
actor ETagStore {
    private var tags: [String: String] = [:]

    func tag(for key: String) -> String? {
        tags[key]
    }

    func remember(_ tag: String?, for key: String) {
        tags[key] = tag
    }
}
