import SwiftUI

/// What a list shows instead of rows: skeletons while loading, a friendly
/// empty state, or the error with "Try again".
public struct StateView<Actions: View>: View {
    public enum Kind {
        case loading(rows: Int = 5)
        case empty(emoji: String, title: String, body: String?)
        case error(message: String, retry: (() -> Void)?)
    }

    private let kind: Kind
    private let actions: Actions

    public init(_ kind: Kind, @ViewBuilder actions: () -> Actions = { EmptyView() }) {
        self.kind = kind
        self.actions = actions()
    }

    public var body: some View {
        switch kind {
        case .loading(let rows):
            VStack(spacing: Metrics.m) {
                ForEach(0..<rows, id: \.self) { _ in SkeletonRow() }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Loading")
        case .empty(let emoji, let title, let body):
            VStack(spacing: Metrics.s) {
                Text(emoji).font(.largeTitle).accessibilityHidden(true)
                Text(title).font(Typography.rowTitle).foregroundStyle(Palette.ink)
                if let body {
                    Text(body).font(Typography.body).foregroundStyle(Palette.inkMuted)
                }
                actions
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(Metrics.xl)
        case .error(let message, let retry):
            VStack(spacing: Metrics.s) {
                Text("⚠️").font(.title).accessibilityHidden(true)
                Text(message).font(Typography.body).foregroundStyle(Palette.inkMuted)
                if let retry {
                    Button("Try again", action: retry).buttonStyle(ChipStyle())
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(Metrics.xl)
        }
    }
}

/// A grey stand-in for a row while it loads.
struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: Metrics.m) {
            RoundedRectangle(cornerRadius: Metrics.thumbRadius).frame(width: 72, height: 72)
            VStack(alignment: .leading, spacing: Metrics.s) {
                Capsule().frame(width: 160, height: 12)
                Capsule().frame(width: 220, height: 10)
                Capsule().frame(width: 120, height: 10)
            }
            Spacer()
        }
        .foregroundStyle(Palette.surfaceSunken)
        .padding(.horizontal, Metrics.m)
    }
}

#Preview {
    VStack {
        StateView(.loading(rows: 2))
        StateView(.empty(emoji: "🍺", title: "Nothing doing", body: "No pubs round here. Bleak, frankly.")) {
            Button("🍸 Include bars") {}.buttonStyle(ChipStyle())
        }
        StateView(.error(message: "Couldn't reach PubDB just now.", retry: {}))
    }
}
