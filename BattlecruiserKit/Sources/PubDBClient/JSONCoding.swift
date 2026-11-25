import Foundation

/// One decoder and encoder for the whole client. The API's dates arrive as
/// strings with ready-made labels, so neither needs a date strategy.
enum JSONCoding {
    static let decoder = JSONDecoder()
    static let encoder = JSONEncoder()
}
