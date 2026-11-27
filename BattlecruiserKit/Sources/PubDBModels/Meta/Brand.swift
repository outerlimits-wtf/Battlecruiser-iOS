import Foundation

/// A pub company or chain as `GET /brands` lists it: every name in the data,
/// from the scrape and from `brand` contributions, with how many pubs carry it.
/// Shown to people as the pub's operator.
public struct Brand: Decodable, Hashable, Sendable, Identifiable {
    public let name: String
    public let count: Int

    public var id: String { name }

    public init(name: String, count: Int) {
        self.name = name
        self.count = count
    }
}

/// The body of `GET /brands`: most pubs first, then alphabetically.
public struct BrandList: Decodable, Sendable {
    public let brands: [Brand]
}
