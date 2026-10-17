import SwiftUI
import PubDBModels

/// Photo, name, where it is, and whether it still trades.
struct DetailHeader: View {
    let summary: PubSummary
    let city: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let photo = summary.photo {
                PhotoView(photo: photo)
            }
            Text(summary.name)
                .font(.title2.bold())
            if !addressLine.isEmpty {
                Text(addressLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                if let distance = summary.distance {
                    Label(distance.label, systemImage: "figure.walk")
                }
                if let rating = summary.rating {
                    Label("\(rating.formatted(.number.precision(.fractionLength(0...1))))/10 (\(summary.reviewCount))", systemImage: "star")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            if !summary.status.serving {
                // Shut down, or shut for now: the server's label says which.
                Label(summary.status.label, systemImage: "exclamationmark.triangle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
    }

    private var addressLine: String {
        [summary.amenity.label, summary.address, summary.postcode, city]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}

/// The pub's photo with its credit. Showing the attribution and licence is a
/// condition of using Commons photos (docs/backend/02-data-model.md).
private struct PhotoView: View {
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
