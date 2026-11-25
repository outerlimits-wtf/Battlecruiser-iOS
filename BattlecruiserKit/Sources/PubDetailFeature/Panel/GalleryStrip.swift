import SwiftUI
import DesignSystem
import PubDBModels

/// The web's photo strip at the top of the panel: a sideways carousel, each
/// photo full height with its credit, or the placeholder when there are none.
struct GalleryStrip: View {
    let photos: [Photo]
    let name: String
    let emoji: String

    static let height: CGFloat = 192

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    if photos.isEmpty {
                        PubPhoto(nil, name: name, emoji: emoji)
                            .frame(width: proxy.size.width, height: Self.height)
                    } else {
                        ForEach(Array(photos.enumerated()), id: \.offset) { _, photo in
                            PubPhoto(photo, name: name, emoji: emoji)
                                .frame(width: photos.count == 1 ? proxy.size.width : proxy.size.width * 0.9, height: Self.height)
                                .overlay(alignment: .bottomLeading) {
                                    PhotoCredit(photo, onPhoto: true).padding(Metrics.s)
                                }
                                .accessibilityElement(children: .contain)
                                .accessibilityLabel(photo.caption ?? "Photo of \(name)")
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
        .frame(height: Self.height)
        .background(Palette.photoBackdrop)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: Metrics.sheetRadius, topTrailingRadius: Metrics.sheetRadius))
    }
}
