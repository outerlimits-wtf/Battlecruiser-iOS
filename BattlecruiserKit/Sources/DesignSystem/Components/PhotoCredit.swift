import SwiftUI
import PubDBModels

/// "{attribution} · {license}", linked to the photo's page when it has one.
/// Showing it is a licence condition (CC BY / BY-SA), so it goes with every photo.
public struct PhotoCredit: View {
    private let photo: Photo
    private let onPhoto: Bool

    /// - Parameter onPhoto: Drawn on a dark scrim over the photo, as in the gallery.
    public init(_ photo: Photo, onPhoto: Bool = false) {
        self.photo = photo
        self.onPhoto = onPhoto
    }

    public var body: some View {
        if let text {
            Group {
                if let link = photo.descriptionURL {
                    Link(text, destination: link)
                } else {
                    Text(text)
                }
            }
            .font(Typography.micro)
            .lineLimit(1)
            .foregroundStyle(onPhoto ? Palette.onPhoto : Palette.inkMuted)
            .padding(.horizontal, onPhoto ? 6 : 0)
            .padding(.vertical, onPhoto ? 2 : 0)
            .background(onPhoto ? Color.black.opacity(0.5) : .clear, in: RoundedRectangle(cornerRadius: 4))
            .accessibilityLabel("Photo: \(text)")
        }
    }

    private var text: String? {
        let parts = [photo.attribution, photo.license].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
