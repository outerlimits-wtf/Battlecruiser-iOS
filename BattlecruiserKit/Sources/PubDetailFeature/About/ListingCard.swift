import SwiftUI
import DesignSystem
import PubDBModels

/// A listed building's designation, with its Wikipedia page when there is one.
struct ListingCard: View {
    let heritage: Heritage

    var body: some View {
        if let designation = heritage.designation {
            VStack(alignment: .leading, spacing: Metrics.s) {
                SectionHeader("Listed")
                Text("🏛️ \(designation)").font(Typography.body).foregroundStyle(Palette.ink)
                if let url = heritage.wikipediaURL {
                    Link("Read about it on Wikipedia", destination: url)
                        .font(Typography.body)
                        .foregroundStyle(Palette.beer)
                }
            }
        }
    }
}
