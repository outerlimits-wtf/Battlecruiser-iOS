import SwiftUI
import AppEnvironment
import DesignSystem
import PubDBClient
import PubDBModels

/// "Going out as @you": a score on the server's scale and a few words.
struct ReviewComposer: View {
    let pubID: String
    let context: PanelContext
    let onPosted: (WriteResult) -> Void

    @State private var rating: Int?
    @State private var text = ""
    @State private var isPosting = false
    @State private var error: String?

    var body: some View {
        let limits = context.meta?.limits
        VStack(alignment: .leading, spacing: Metrics.s) {
            Text("Going out as **\(context.session.user?.label ?? "Anonymous")**")
                .font(Typography.secondary)
                .foregroundStyle(Palette.inkMuted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach((limits?.minRating ?? 1)...(limits?.maxRating ?? 10), id: \.self) { score in
                        Button("\(score)") { rating = score }
                            .font(Typography.body.weight(.semibold))
                            .frame(width: 32, height: 32)
                            .foregroundStyle(rating == score ? Palette.onBeer : Palette.ink)
                            .background(rating == score ? Palette.beer : Palette.surfaceSunken, in: Circle())
                            .accessibilityLabel("\(score) out of \(limits?.maxRating ?? 10)")
                            .accessibilityAddTraits(rating == score ? .isSelected : [])
                    }
                }
            }
            TextField("Great pint, shocking carpet…", text: $text, axis: .vertical)
                .lineLimit(3...6)
                .padding(Metrics.m)
                .background(Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: Metrics.inputRadius))
                .onChange(of: text) { _, value in
                    let max = limits?.maxReviewBody ?? 2000
                    if value.count > max { text = String(value.prefix(max)) }
                }
            if let error {
                Text(error).font(Typography.secondary).foregroundStyle(Palette.bad)
            }
            Button(isPosting ? "Posting…" : "Post", action: post)
                .buttonStyle(ChipStyle(isSelected: true))
                .disabled(isPosting)
        }
        .padding(Metrics.l)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Metrics.cardRadius).stroke(Palette.surfaceSunken))
    }

    private func post() {
        guard let rating else {
            let limits = context.meta?.limits
            error = "Pick a rating from \(limits?.minRating ?? 1) to \(limits?.maxRating ?? 10)."
            return
        }
        isPosting = true
        error = nil
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            defer { isPosting = false }
            do {
                let result = try await context.writer.postReview(pubID, rating: rating, body: body.isEmpty ? nil : body)
                self.rating = nil
                text = ""
                onPosted(result)
            } catch {
                self.error = PubDBError.wrapping(error)?.userMessage
            }
        }
    }
}
