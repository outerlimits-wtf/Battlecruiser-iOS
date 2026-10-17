import Foundation

/// A response as it came from the server, and when.
public struct CachedResponse: Equatable, Sendable {
    /// The raw response body, exactly as received, so it decodes the same way
    /// a fresh one does.
    public let data: Data
    /// When the server sent it. Open states in it are true only for this moment.
    public let fetchedAt: Date

    public init(data: Data, fetchedAt: Date) {
        self.data = data
        self.fetchedAt = fetchedAt
    }
}

/// Recent server responses on disk, so the app can show something at once on
/// launch or without signal (docs/backend/04-ios-integration.md §5).
///
/// One file per key, holding the raw response body; the file's modification
/// date records when it was fetched, so every file stays plain JSON. Lives in
/// `Caches/`, which iOS may empty: the app must cope with an empty cache anyway.
/// Nothing here throws. A cache that cannot read or write behaves as empty.
public actor ResponseCache {
    private let directory: URL
    private let maxEntries: Int
    private let fileManager = FileManager.default

    /// - Parameters:
    ///   - directory: Where to keep the files; created if missing.
    ///   - maxEntries: Beyond this many, the oldest responses are removed.
    public init(directory: URL, maxEntries: Int = 60) {
        self.directory = directory
        self.maxEntries = maxEntries
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// The app's cache, in `Caches/ResponseCache`.
    public static func standard() -> ResponseCache {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return ResponseCache(directory: caches.appending(path: "ResponseCache", directoryHint: .isDirectory))
    }

    /// Keep `data` under `key`, replacing anything already there.
    public func store(_ data: Data, for key: String, fetchedAt: Date) {
        let file = fileURL(for: key)
        do {
            try data.write(to: file, options: .atomic)
            try fileManager.setAttributes([.modificationDate: fetchedAt], ofItemAtPath: file.path(percentEncoded: false))
        } catch {
            // A half-written entry is worse than none.
            try? fileManager.removeItem(at: file)
            return
        }
        evictOldest()
    }

    /// The response stored under `key`, if any.
    public func load(_ key: String) -> CachedResponse? {
        let file = fileURL(for: key)
        guard let data = try? Data(contentsOf: file), let fetchedAt = modificationDate(of: file) else {
            return nil
        }
        return CachedResponse(data: data, fetchedAt: fetchedAt)
    }

    public func remove(_ key: String) {
        try? fileManager.removeItem(at: fileURL(for: key))
    }

    public func removeAll() {
        for file in storedFiles() {
            try? fileManager.removeItem(at: file)
        }
    }

    // MARK: - Files

    /// Keys can hold any characters ("pub/node/123"). Percent-encoding everything
    /// but letters and digits gives a safe file name that no other key shares.
    private func fileURL(for key: String) -> URL {
        let name = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        return directory.appending(path: name + ".json", directoryHint: .notDirectory)
    }

    private func storedFiles() -> [URL] {
        let files = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        return (files ?? []).filter { $0.pathExtension == "json" }
    }

    private func modificationDate(of file: URL) -> Date? {
        try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    /// Remove the oldest responses beyond `maxEntries`.
    private func evictOldest() {
        let files = storedFiles()
        guard files.count > maxEntries else {
            return
        }
        let oldestFirst = files.sorted { first, second in
            (modificationDate(of: first) ?? .distantPast) < (modificationDate(of: second) ?? .distantPast)
        }
        for file in oldestFirst.prefix(files.count - maxEntries) {
            try? fileManager.removeItem(at: file)
        }
    }
}
