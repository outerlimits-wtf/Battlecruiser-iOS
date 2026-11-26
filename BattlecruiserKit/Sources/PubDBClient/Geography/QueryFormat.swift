import Foundation

enum QueryFormat {
    /// Five decimal places is about a metre: plenty for a map, and it keeps URLs
    /// short and stable. `String(format:)` without a locale always uses a ".".
    static func degrees(_ value: Double) -> String {
        String(format: "%.5f", value)
    }
}
