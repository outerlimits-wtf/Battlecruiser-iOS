import SwiftUI
import PubDBModels

/// Getting there and getting in touch. Directions go by coordinate, not by
/// name, so Apple Maps never guesses which Red Lion you meant.
struct ContactSection: View {
    let summary: PubSummary
    let contact: Contact

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("Get there")
            // A row of buttons when they fit; a column at large text sizes.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    buttons
                }
                VStack(alignment: .leading, spacing: 10) {
                    buttons
                }
            }
            .font(.subheadline)
        }
    }

    @ViewBuilder
    private var buttons: some View {
        if let directions {
            Link(destination: directions) {
                Label("Walk there", systemImage: "figure.walk")
            }
            .buttonStyle(.borderedProminent)
        }
        if let phone = contact.phone, let call = phoneURL(phone) {
            Link(destination: call) {
                Label("Call", systemImage: "phone")
            }
            .buttonStyle(.bordered)
        }
        if let website = contact.websiteURL {
            Link(destination: website) {
                Label("Website", systemImage: "safari")
            }
            .buttonStyle(.bordered)
        }
    }

    /// Walking directions in Apple Maps to the pub's coordinate.
    private var directions: URL? {
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [
            URLQueryItem(name: "daddr", value: "\(summary.lat),\(summary.lon)"),
            URLQueryItem(name: "dirflg", value: "w"),
        ]
        return components?.url
    }

    private func phoneURL(_ phone: String) -> URL? {
        let dialable = phone.filter { $0.isNumber || $0 == "+" }
        guard !dialable.isEmpty else {
            return nil
        }
        return URL(string: "tel:\(dialable)")
    }
}
