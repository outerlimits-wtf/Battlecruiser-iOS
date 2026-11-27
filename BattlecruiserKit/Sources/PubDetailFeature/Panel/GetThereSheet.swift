import SwiftUI
import DesignSystem

/// "Get there": the pub's name and a link per maps app.
struct GetThereSheet: View {
    let name: String
    let links: [DirectionsLink]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.m) {
            Text("Get there").font(Typography.title).foregroundStyle(Palette.ink)
            Text(name).font(Typography.body).foregroundStyle(Palette.inkMuted)
            ForEach(links) { link in
                Link(destination: link.url) {
                    HStack(spacing: Metrics.m) {
                        Text(link.emoji).accessibilityHidden(true)
                        Text(link.label).font(Typography.rowTitle)
                        Spacer()
                        Image(systemName: "arrow.up.right").foregroundStyle(Palette.inkFaint)
                    }
                    .padding(Metrics.m)
                    .frame(minHeight: Metrics.minTap)
                    .background(Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: Metrics.inputRadius))
                }
                .foregroundStyle(Palette.ink)
            }
            Button("Cancel") { dismiss() }
                .frame(maxWidth: .infinity)
                .padding(.top, Metrics.s)
                .foregroundStyle(Palette.inkMuted)
        }
        .padding(Metrics.xl)
        .presentationDetents([.medium])
        .presentationBackground(Palette.surface)
    }
}
