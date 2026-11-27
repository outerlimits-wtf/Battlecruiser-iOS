import SwiftUI
import DesignSystem

/// "Everything else we know (n)": the pub's OpenStreetMap tags, folded away.
/// Raw keys for now: the server is asked (S7) to send them filtered and
/// labelled, which replaces the filter here.
struct EverythingElse: View {
    let tags: [String: String]
    @State private var isExpanded = false

    var body: some View {
        let shown = tags.filter { !Self.hidden.contains($0.key) && !$0.value.isEmpty }.sorted { $0.key < $1.key }
        if !shown.isEmpty {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(shown, id: \.key) { key, value in
                        HStack(alignment: .firstTextBaseline) {
                            Text(key).foregroundStyle(Palette.inkMuted)
                            Spacer(minLength: Metrics.m)
                            if let url = URL(string: value), url.scheme?.hasPrefix("http") == true {
                                Link(value, destination: url).lineLimit(1)
                            } else {
                                Text(value).foregroundStyle(Palette.ink).multilineTextAlignment(.trailing)
                            }
                        }
                        .font(Typography.secondary)
                    }
                }
                .padding(.top, Metrics.s)
            } label: {
                Text("Everything else we know (\(shown.count))")
                    .font(Typography.body.weight(.semibold))
                    .foregroundStyle(Palette.ink)
            }
            .tint(Palette.inkMuted)
        }
    }

    /// Shown elsewhere already, as the web leaves them out.
    static let hidden: Set = ["name", "amenity"]
}
