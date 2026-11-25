import SwiftUI
import PubDBModels

/// The pub's photo with its credit. Showing the attribution and licence is a
/// condition of using Commons photos (docs/backend/02-data-model.md).
struct PhotoView: View {
    let photo: Photo

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            AsyncImage(url: photo.thumbnailURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.secondary.opacity(0.1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityHidden(true)

            if let credit {
                if let link = photo.descriptionURL {
                    Link(credit, destination: link)
                        .font(.caption2)
                } else {
                    Text(credit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var credit: String? {
        let parts = [photo.attribution, photo.license].compactMap { $0 }.filter { !$0.isEmpty }
        guard !parts.isEmpty else {
            return nil
        }
        return "Photo: " + parts.joined(separator: " · ")
    }
}
