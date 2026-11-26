import SwiftUI
import DesignSystem

/// The panel's three tabs, as on the web.
enum PanelTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case reviews = "Reviews"
    case about = "About"

    var id: Self { self }
}

/// The sticky tab bar: the active tab underlined in ink.
struct PanelTabBar: View {
    @Binding var selection: PanelTab
    let reviewCount: Int

    var body: some View {
        HStack(spacing: Metrics.xl) {
            ForEach(PanelTab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 6) {
                        Text(title(tab))
                            .font(Typography.body.weight(.semibold))
                            .foregroundStyle(selection == tab ? Palette.ink : Palette.inkMuted)
                        Rectangle()
                            .fill(selection == tab ? Palette.ink : .clear)
                            .frame(height: 2)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(minHeight: Metrics.minTap)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == tab ? [.isSelected, .isButton] : .isButton)
            }
            Spacer()
        }
        .padding(.horizontal, Metrics.l)
        .background(Palette.surface)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.surfaceSunken).frame(height: 1)
        }
    }

    private func title(_ tab: PanelTab) -> String {
        tab == .reviews && reviewCount > 0 ? "Reviews (\(reviewCount))" : tab.rawValue
    }
}
