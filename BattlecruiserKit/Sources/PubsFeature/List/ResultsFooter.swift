import SwiftUI
import DesignSystem
import PubDBClient

/// Under the last card: that's the lot (or that the list was cut short), the
/// same ways out as the empty state, and the OSM credit (a licence condition
/// wherever OSM data is shown).
struct ResultsFooter: View {
    let count: Int
    /// Nil when bars are already included.
    var onIncludeBars: (() -> Void)? = nil
    /// Nil when no filters are set.
    var onClearFilters: (() -> Void)? = nil
    /// Nil when already searching everywhere.
    var onSearchEverywhere: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Metrics.m) {
            Text(message)
                .font(Typography.secondary)
                .foregroundStyle(Palette.inkMuted)
                .multilineTextAlignment(.center)
            if onIncludeBars != nil || onClearFilters != nil || onSearchEverywhere != nil {
                ChipFlow {
                    if let onClearFilters {
                        Button("Clear all filters", action: onClearFilters).buttonStyle(ChipStyle())
                    }
                    if let onIncludeBars {
                        Button("🍸 Include bars", action: onIncludeBars).buttonStyle(ChipStyle())
                    }
                    if let onSearchEverywhere {
                        Button("🌍 Search everywhere", action: onSearchEverywhere).buttonStyle(ChipStyle())
                    }
                }
            }
            Text("Pub data © OpenStreetMap contributors")
                .font(Typography.micro)
                .foregroundStyle(Palette.inkFaint)
        }
        .padding(Metrics.l)
        .frame(maxWidth: .infinity)
    }

    private var message: String {
        // S1 asks the server for a `truncated` flag instead of this guess.
        if count >= PubDBClient.defaultLimit {
            return "Showing the closest \(count). Zoom in or add a filter to see the rest."
        }
        return Self.lines[count % Self.lines.count]
    }

    /// Picked by the count, so the line holds still while the list does.
    static let lines = [
        "That's the lot. Pick one, you've scrolled enough.",
        "That's all of them. Nobody's opening a new one while you watch.",
        "End of the list. The pub won't come to you.",
        "That's everything round here. Lower your standards or move the map.",
    ]
}
