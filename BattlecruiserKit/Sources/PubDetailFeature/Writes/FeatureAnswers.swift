import SwiftUI
import DesignSystem
import PubDBModels

/// Under "What's there", signed in, as the web: "n not here" (with "Actually
/// yes") and "n to answer" (Yes / No), each folded away until tapped.
struct FeatureAnswers: View {
    let features: [FeatureAnswer]
    let writer: FactWriter

    @State private var showsNo = false
    @State private var showsUnknown = false

    var body: some View {
        let no = features.filter { $0.value == .no }
        let unknown = features.filter { $0.value == .unknown }
        VStack(alignment: .leading, spacing: Metrics.s) {
            if !no.isEmpty {
                fold("\(no.count) not here", isOpen: $showsNo, highlighted: false)
                if showsNo {
                    ForEach(no) { feature in
                        row("No \(feature.label.lowercased())", feature) {
                            Button("Actually yes") { writer.send(feature.key, "yes") }.buttonStyle(ChipStyle())
                        }
                    }
                }
            }
            if !unknown.isEmpty {
                fold("\(unknown.count) to answer", isOpen: $showsUnknown, highlighted: true)
                if showsUnknown {
                    Text("Nobody has said either way. Go on, it's one tap.")
                        .font(Typography.secondary)
                        .foregroundStyle(Palette.inkMuted)
                    ForEach(unknown) { feature in
                        row("\(feature.label)?", feature) {
                            Button("Yes") { writer.send(feature.key, "yes") }.buttonStyle(ChipStyle())
                            Button("No") { writer.send(feature.key, "no") }.buttonStyle(ChipStyle())
                        }
                    }
                }
            }
        }
    }

    private func fold(_ title: String, isOpen: Binding<Bool>, highlighted: Bool) -> some View {
        Button {
            isOpen.wrappedValue.toggle()
        } label: {
            Text("\(title) \(isOpen.wrappedValue ? "▴" : "▾")")
        }
        .buttonStyle(ChipStyle())
        .background(highlighted ? Palette.beerSoft : .clear, in: Capsule())
    }

    private func row(_ title: String, _ feature: FeatureAnswer, @ViewBuilder actions: () -> some View) -> some View {
        HStack(spacing: Metrics.s) {
            SymbolGlyph(feature.symbol, size: 15)
            Text(title).font(Typography.body).foregroundStyle(Palette.ink)
            Spacer()
            actions()
        }
    }
}
