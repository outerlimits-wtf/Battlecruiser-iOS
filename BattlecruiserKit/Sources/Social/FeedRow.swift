import SwiftUI
import AppEnvironment
import DesignSystem
import PubDBModels

/// One update: who and when, the pub, then the fact or the review. Tap the
/// person for their profile, anywhere else for the pub.
struct FeedRow: View {
    let entry: FeedEntry
    let onOpenPub: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: Metrics.s) {
                author
                Spacer()
                Text(entry.agoLabel).font(Typography.secondary).foregroundStyle(Palette.inkFaint)
            }
            Button(action: onOpenPub) { update }
                .buttonStyle(.plain)
                .accessibilityHint("Shows the pub")
        }
        .padding(.horizontal, Metrics.l)
        .padding(.vertical, Metrics.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) { Rectangle().fill(Palette.surfaceSunken).frame(height: 1) }
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpenPub)
        .accessibilityElement(children: .contain)
    }

    /// A person links to their profile (on the Social tab's stack); a data
    /// source is just a name.
    @ViewBuilder
    private var author: some View {
        let label = HStack(spacing: Metrics.s) {
            Avatar(url: entry.avatarURL, name: entry.attribution.label, size: .xs)
            Text(entry.attribution.label)
                .font(Typography.secondary.weight(.semibold))
                .foregroundStyle(entry.attribution.kind == "user" ? Palette.beer : Palette.inkFaint)
        }
        if let link = ProfileLink(entry.attribution) {
            NavigationLink(value: link) { label.contentShape(Rectangle()) }
                .buttonStyle(.plain)
                .accessibilityHint("Shows their profile")
        } else {
            label
        }
    }

    private var update: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.pub.name).font(Typography.rowTitle).foregroundStyle(Palette.ink)
            if entry.isReview {
                HStack(alignment: .firstTextBaseline, spacing: Metrics.s) {
                    if let rating = entry.rating {
                        Text("\(rating)/10").font(Typography.body.weight(.semibold)).foregroundStyle(Palette.beer)
                    }
                    if let body = entry.body, !body.isEmpty {
                        Text("“\(body)”").font(Typography.body).foregroundStyle(Palette.inkMuted).lineLimit(2)
                    }
                }
            } else if let label = entry.fieldLabel, let value = entry.displayValue {
                HStack(alignment: .firstTextBaseline, spacing: Metrics.s) {
                    Text(label.uppercased()).font(Typography.sectionHeader).foregroundStyle(Palette.inkMuted)
                    Text(value).font(Typography.body).foregroundStyle(Palette.ink).lineLimit(2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
