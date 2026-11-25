import Foundation

/// A dotted version such as "1.4" or "0.10.2", compared part by part as
/// numbers, so "0.10" is newer than "0.9". Missing parts count as zero.
public struct AppVersion: Comparable, Hashable, Sendable, CustomStringConvertible {
    public let parts: [Int]

    /// Nil when the string is empty or any part is not a number.
    public init?(_ string: String) {
        let pieces = string.trimmingCharacters(in: .whitespaces).split(separator: ".", omittingEmptySubsequences: false)
        let numbers = pieces.compactMap { Int($0) }
        guard !pieces.isEmpty, numbers.count == pieces.count, numbers.allSatisfy({ $0 >= 0 }) else {
            return nil
        }
        parts = numbers
    }

    public var description: String {
        parts.map(String.init).joined(separator: ".")
    }

    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let count = Swift.max(lhs.parts.count, rhs.parts.count)
        for index in 0..<count {
            let left = index < lhs.parts.count ? lhs.parts[index] : 0
            let right = index < rhs.parts.count ? rhs.parts[index] : 0
            if left != right {
                return left < right
            }
        }
        return false
    }

    public static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
        !(lhs < rhs) && !(rhs < lhs)
    }

    public func hash(into hasher: inout Hasher) {
        var trimmed = parts
        while trimmed.last == 0 { trimmed.removeLast() }
        hasher.combine(trimmed)
    }

    /// Whether this build may run under the server's floor. No floor, or a floor
    /// this build cannot read, lets it run: a typo on the server must not lock
    /// everyone out.
    public func isAllowed(minimum: String?) -> Bool {
        guard let minimum, let floor = AppVersion(minimum) else {
            return true
        }
        return self >= floor
    }
}
