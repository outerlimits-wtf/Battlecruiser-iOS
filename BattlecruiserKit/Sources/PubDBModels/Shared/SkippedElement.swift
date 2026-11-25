import Foundation

/// Decodes any JSON value without reading it, to step past a bad array element.
struct SkippedElement: Decodable {
    init(from decoder: any Decoder) throws {}
}
