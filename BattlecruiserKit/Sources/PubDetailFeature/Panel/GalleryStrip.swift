import SwiftUI
import DesignSystem
import PubDBModels

/// The web's photo strip at the top of the panel: a sideways carousel, each
/// photo full height with its credit, or the placeholder when there are none.
struct GalleryStrip: View {
    let photos: [Photo]
    let name: String
    let emoji: String
    /// Signed in: the "+ Add a photo" tile at the end.
    var onAdd: (() -> Void)? = nil
    /// Signed in: Report on photos people uploaded.
    var onReport: ((Photo) -> Void)? = nil

    static let height: CGFloat = 192

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    if photos.isEmpty {
                        PubPhoto(nil, name: name, emoji: emoji)
                            .frame(width: proxy.size.width * (onAdd == nil ? 1 : 0.7), height: Self.height)
                    } else {
                        ForEach(Array(photos.enumerated()), id: \.offset) { _, photo in
                            PubPhoto(photo, name: name, emoji: emoji)
                                .frame(width: photos.count == 1 && onAdd == nil ? proxy.size.width : proxy.size.width * 0.9, height: Self.height)
                                .overlay(alignment: .bottomLeading) {
                                    PhotoCredit(photo, onPhoto: true).padding(Metrics.s)
                                }
                                .overlay(alignment: .topLeading) {
                                    if let onReport, photo.id != nil {
                                        Button("Report") { onReport(photo) }
                                            .font(Typography.secondary.weight(.semibold))
                                            .foregroundStyle(Palette.onPhoto)
                                            .padding(.horizontal, Metrics.s)
                                            .padding(.vertical, 4)
                                            .background(.black.opacity(0.5), in: Capsule())
                                            .padding(Metrics.s)
                                    }
                                }
                                .accessibilityElement(children: .contain)
                                .accessibilityLabel(photo.caption ?? "Photo of \(name)")
                        }
                    }
                    if let onAdd {
                        Button(action: onAdd) {
                            Label("Add a photo", systemImage: "plus")
                                .font(Typography.body.weight(.semibold))
                                .foregroundStyle(Palette.onPhoto)
                                .frame(width: proxy.size.width * 0.4, height: Self.height)
                                .background(.white.opacity(0.12))
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
        .frame(height: Self.height)
        .background(Palette.photoBackdrop)
    }
}
