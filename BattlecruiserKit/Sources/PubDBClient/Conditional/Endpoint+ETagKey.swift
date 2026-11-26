import Foundation

extension Endpoint {
    /// What an `ETag` is remembered under: the path and query, minus `at`, in a
    /// fixed order. `/pins` keeps one tag per filter set, and `at` changes on
    /// every call, so it must not be part of the key.
    var etagKey: String {
        let items = query
            .filter { $0.name != "at" }
            .map { "\($0.name)=\($0.value ?? "")" }
            .sorted()
        return path.joined(separator: "/") + "?" + items.joined(separator: "&")
    }
}
