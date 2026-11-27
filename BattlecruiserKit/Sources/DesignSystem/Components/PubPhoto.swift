import SwiftUI
import PubDBModels

/// A pub's photo: the full image, falling back to the thumbnail, falling back
/// to a placeholder tinted from the pub's name with its emoji. Never blank.
public struct PubPhoto: View {
    public enum Size {
        /// The 72pt square in a list row.
        case thumbnail
        /// As large as it is laid out, filling it and cropped to fit.
        case full
        /// The full image, never cropped or stretched: given a height and no
        /// width, it is as wide as its shape makes it.
        case natural
    }

    private let photo: Photo?
    private let name: String
    private let emoji: String
    private let size: Size

    public init(_ photo: Photo?, name: String, emoji: String, size: Size = .full) {
        self.photo = photo
        self.name = name
        self.emoji = emoji
        self.size = size
    }

    public var body: some View {
        // Rows want the thumbnail; everything else the full image. Either way
        // the other size is the fallback (spec: url, then thumbUrl).
        let (primary, secondary) = size == .thumbnail
            ? (photo?.thumbnailURL, photo?.imageURL)
            : (photo?.imageURL, photo?.thumbnailURL)
        image(primary) {
            image(secondary) { PhotoPlaceholder(name: name, emoji: emoji) }
        }
        .clipped()
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func image(_ url: URL?, orElse fallback: @escaping () -> some View) -> some View {
        if let url {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    if size == .natural {
                        image.resizable().scaledToFit()
                    } else {
                        image.resizable().scaledToFill()
                    }
                } else if phase.error != nil {
                    fallback()
                } else {
                    Palette.surfaceSunken
                }
            }
        } else {
            fallback()
        }
    }
}

/// A soft gradient whose hue comes from the name, so each pub keeps its own.
struct PhotoPlaceholder: View {
    let name: String
    let emoji: String

    var body: some View {
        let hue = Double(name.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF } % 360) / 360
        LinearGradient(
            colors: [Color(hue: hue, saturation: 0.35, brightness: 0.85), Color(hue: hue, saturation: 0.5, brightness: 0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(Text(emoji).font(.title))
    }
}

#Preview {
    HStack {
        PubPhoto(nil, name: "The Bedford", emoji: "🍺", size: .thumbnail)
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.thumbRadius))
        PubPhoto(nil, name: "The Devonshire", emoji: "🍽️", size: .thumbnail)
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.thumbRadius))
    }
    .padding()
}
