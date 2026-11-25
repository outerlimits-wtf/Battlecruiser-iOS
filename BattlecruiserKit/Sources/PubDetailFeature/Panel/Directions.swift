import Foundation

/// Hand the pub to whatever the drinker navigates with, as the web's
/// `lib/directions.ts`. All three are universal links: the app if installed,
/// else the website. By coordinate, so no map guesses which Red Lion.
struct DirectionsLink: Identifiable, Equatable {
    let id: String
    let label: String
    let emoji: String
    let url: URL

    static func all(name: String, latitude: Double, longitude: Double) -> [DirectionsLink] {
        let coord = "\(latitude),\(longitude)"
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        let links: [(String, String, String, String)] = [
            ("google", "Google Maps", "🗺️", "https://www.google.com/maps/dir/?api=1&destination=\(coord)"),
            ("citymapper", "Citymapper", "🚇", "https://citymapper.com/directions?endcoord=\(coord)&endname=\(encodedName)"),
            ("apple", "Apple Maps", "🍎", "https://maps.apple.com/?daddr=\(coord)&q=\(encodedName)"),
        ]
        return links.compactMap { id, label, emoji, string in
            URL(string: string).map { DirectionsLink(id: id, label: label, emoji: emoji, url: $0) }
        }
    }
}
