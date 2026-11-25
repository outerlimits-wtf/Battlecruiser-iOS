import SwiftUI
import DesignSystem
import PubDBModels

/// The fine print: where the data came from (a licence condition, decision
/// P4), and the pub's id. The server picks which sources are shown (S15).
struct AboutFooter: View {
    let sources: [DataSource]
    let id: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Text("Sources: ")
                ForEach(Array(sources.enumerated()), id: \.element.id) { index, source in
                    if index > 0 { Text(" · ") }
                    if let url = source.linkURL {
                        Link(source.label, destination: url)
                    } else {
                        Text(source.label)
                    }
                }
                if sources.isEmpty { Text("OpenStreetMap") }
            }
            Text(id).monospaced()
        }
        .font(Typography.micro)
        .foregroundStyle(Palette.inkFaint)
        .tint(Palette.inkMuted)
    }
}
