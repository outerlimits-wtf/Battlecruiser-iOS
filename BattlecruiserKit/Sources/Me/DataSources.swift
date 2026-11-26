import SwiftUI
import DesignSystem

/// "WHERE THE DATA'S FROM": each source named with its licence. Required.
struct DataSources: View {
    private let sources: [(name: String, link: String, what: String)] = [
        ("OpenStreetMap", "https://www.openstreetmap.org/copyright",
         "pubs, names, tags and old names. © OpenStreetMap contributors, licensed under the ODbL."),
        ("Food Standards Agency", "https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/",
         "addresses, postcodes and a few hundred pubs OpenStreetMap has never had. © Crown copyright, Open Government Licence v3.0."),
        ("Wikidata", "https://creativecommons.org/publicdomain/zero/1.0/",
         "listed buildings and the year it went up, released under CC0."),
        ("Wikimedia Commons", "https://commons.wikimedia.org/",
         "photos, licensed per file, usually CC BY or CC BY-SA, each credited under the photo itself."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.s) {
            SectionHeader("Where the data's from")
            ForEach(sources, id: \.name) { source in
                if let url = URL(string: source.link) {
                    (Text("[\(source.name)](\(url.absoluteString))").bold() + Text(": \(source.what)"))
                        .tint(Palette.beer)
                }
            }
            Text("Everything else was typed in by somebody who drank there.")
        }
    }
}
