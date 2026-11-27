import SwiftUI
import DesignSystem

/// One of the round buttons under the pub's name: a 44 pt circle with a
/// small label underneath.
struct ActionButton: View {
    let title: String
    let systemImage: String
    var isPrimary = false
    var isOn = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(foreground)
                    .frame(width: 44, height: 44)
                    .background(background, in: Circle())
                Text(title)
                    .font(Typography.secondary)
                    .foregroundStyle(isOn ? Palette.beer : Palette.ink)
            }
            .frame(minWidth: 64)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private var foreground: Color {
        isPrimary ? Palette.onInk : (isOn ? Palette.beer : Palette.ink)
    }

    private var background: Color {
        isPrimary ? Palette.ink : (isOn ? Palette.beerSoft : Palette.surfaceSunken)
    }
}
