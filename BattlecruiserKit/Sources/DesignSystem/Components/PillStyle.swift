import SwiftUI

/// The rounded pills in the filter row and action bars: ink when active,
/// surface with a float shadow when not.
public struct PillStyle: ButtonStyle {
    private let isActive: Bool

    public init(isActive: Bool = false) {
        self.isActive = isActive
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.pill)
            .lineLimit(1)
            .padding(.horizontal, Metrics.m)
            .frame(minHeight: 32)
            .foregroundStyle(isActive ? Palette.onInk : Palette.ink)
            .background(isActive ? Palette.ink : Palette.surface, in: Capsule())
            .elevation(.float)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

/// The smaller chips inside panels and forms: picked or not.
public struct ChipStyle: ButtonStyle {
    private let isSelected: Bool

    public init(isSelected: Bool = false) {
        self.isSelected = isSelected
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.pill)
            .padding(.horizontal, Metrics.m)
            .padding(.vertical, 6)
            .frame(minHeight: 32)
            .foregroundStyle(isSelected ? Palette.onInk : Palette.ink)
            .background(isSelected ? Palette.ink : Palette.surfaceSunken, in: Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    VStack(spacing: Metrics.m) {
        HStack {
            Button("Open now") {}.buttonStyle(PillStyle(isActive: true))
            Button("Features ▾") {}.buttonStyle(PillStyle())
        }
        HStack {
            Button("🍺 Proper pubs") {}.buttonStyle(ChipStyle(isSelected: true))
            Button("🍸 Bars") {}.buttonStyle(ChipStyle())
        }
    }
    .padding()
    .background(Palette.canvas)
}
