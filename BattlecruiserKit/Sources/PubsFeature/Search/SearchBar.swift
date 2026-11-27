import SwiftUI
import DesignSystem

/// The web's search pill over the map. Hands the text on 250 ms after typing
/// stops, so a word is one fetch, not one per letter.
struct SearchBar: View {
    let onSearch: (String) -> Void
    @State private var text = ""
    @FocusState private var isFocused: Bool

    static let debounce: Duration = .milliseconds(250)

    var body: some View {
        HStack(spacing: Metrics.s) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Palette.inkMuted)
                .accessibilityHidden(true)
            TextField("Search pubs, streets, breweries", text: $text)
                .font(.body)
                .foregroundStyle(Palette.ink)
                .focused($isFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .onSubmit { onSearch(text) }
            if !text.isEmpty {
                Button {
                    text = ""
                    onSearch("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.inkFaint)
                        .frame(minWidth: Metrics.minTap, minHeight: Metrics.minTap)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.leading, Metrics.l)
        .frame(height: 48)
        .background(Palette.surface, in: Capsule())
        .elevation(.float)
        .task(id: text) {
            try? await Task.sleep(for: Self.debounce)
            guard !Task.isCancelled else { return }
            onSearch(text)
        }
    }
}
