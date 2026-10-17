import SwiftUI
import PubDBModels

/// Where this pub's information came from. Displaying these is a licence
/// condition (OpenStreetMap is ODbL), not decoration.
struct SourcesSection: View {
    let sources: [DataSource]

    var body: some View {
        if !sources.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Data from")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(sources) { source in
                    if let link = source.linkURL {
                        Link(label(for: source), destination: link)
                            .font(.caption)
                    } else {
                        Text(label(for: source))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func label(for source: DataSource) -> String {
        source.key == "osm" ? "© \(source.label) contributors" : source.label
    }
}
