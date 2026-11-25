import SwiftUI

/// A person's picture, or the first letter of their handle on beer colour.
public struct Avatar: View {
    public enum Size: CGFloat {
        case xs = 20
        case sm = 28
        case md = 44
        case lg = 72
    }

    private let url: URL?
    private let name: String
    private let size: Size

    public init(url: URL?, name: String, size: Size = .sm) {
        self.url = url
        self.name = name
        self.size = size
    }

    public var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        initial
                    }
                }
            } else {
                initial
            }
        }
        .frame(width: size.rawValue, height: size.rawValue)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    private var initial: some View {
        let letter = name.drop { $0 == "@" }.first.map { String($0).uppercased() } ?? "?"
        return Text(letter)
            .font(.system(size: size.rawValue * 0.45, weight: .semibold))
            .foregroundStyle(Palette.onBeer)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.beer)
    }
}

#Preview {
    HStack {
        Avatar(url: nil, name: "@goatloaf", size: .xs)
        Avatar(url: nil, name: "@goatloaf", size: .sm)
        Avatar(url: nil, name: "@goatloaf", size: .md)
        Avatar(url: nil, name: "@goatloaf", size: .lg)
    }
    .padding()
}
