import SwiftUI

/// 🥇 🥈 🥉 for the top three, then the number in a grey circle.
public struct RankBadge: View {
    private let rank: Int

    public init(_ rank: Int) {
        self.rank = rank
    }

    public var body: some View {
        Group {
            switch rank {
            case 1: Text("🥇")
            case 2: Text("🥈")
            case 3: Text("🥉")
            default:
                Text("\(rank)")
                    .font(Typography.secondary.weight(.semibold))
                    .foregroundStyle(Palette.inkMuted)
                    .frame(width: 26, height: 26)
                    .background(Palette.surfaceSunken, in: Circle())
            }
        }
        .frame(minWidth: 28)
        .accessibilityLabel("Number \(rank)")
    }
}

#Preview {
    HStack { ForEach(1...5, id: \.self) { RankBadge($0) } }.padding()
}
