import Foundation

/// Query items more than one area of the API takes.
enum QueryItems {
    /// `lat` and `lon`, both or neither: the server adds distances from here.
    static func location(_ location: Coordinate?) -> [URLQueryItem] {
        guard let location else { return [] }
        return [
            URLQueryItem(name: "lat", value: QueryFormat.degrees(location.latitude)),
            URLQueryItem(name: "lon", value: QueryFormat.degrees(location.longitude)),
        ]
    }
}
