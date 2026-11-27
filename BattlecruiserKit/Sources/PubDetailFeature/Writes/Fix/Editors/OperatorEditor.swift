import SwiftUI
import DesignSystem
import PubDBModels

/// The pub's operator (`brand`): a box prefilled with the current one, and
/// below it the known operators with their pub counts, filtered as you type.
/// Tapping one saves it; a name nobody has used yet can be saved as typed,
/// trimmed. The list comes from `GET /brands`.
struct OperatorEditor: View {
    let field: ContributableField
    let current: EditableValue?
    let loadBrands: () async throws -> [Brand]
    let send: (String) -> Void

    @State private var draft = ""
    @State private var brands: [Brand] = []
    @FocusState private var isEditing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.s) {
            TextField(field.placeholder ?? field.label, text: $draft)
                .font(Typography.body)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($isEditing)
                .onSubmit { if let name = matches.newName { save(name) } }
                .accessibilityLabel(field.label)
                .padding(Metrics.s)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.inputRadius))
            if isEditing {
                suggestions
            }
        }
        .onAppear { draft = current?.value ?? "" }
        .onChange(of: current?.value) { _, value in draft = value ?? "" }
        .onChange(of: draft) { _, value in
            if let max = field.maxLength, value.count > max { draft = String(value.prefix(max)) }
        }
        .task { brands = (try? await loadBrands()) ?? [] }
    }

    /// While the box is the current value, every operator is offered (most
    /// pubs first); once it's edited, only those that match.
    private var matches: OperatorMatches {
        OperatorMatches(typed: draft == (current?.value ?? "") ? "" : draft, in: brands)
    }

    private var suggestions: some View {
        let matches = matches
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(matches.brands) { brand in
                row(brand.name, detail: "(\(brand.count))", isCurrent: brand.name == current?.value)
                    .accessibilityLabel("\(brand.name), \(brand.count) \(brand.count == 1 ? "pub" : "pubs")")
            }
            if let name = matches.newName {
                row("Use “\(name)”", detail: nil, isCurrent: false, value: name)
                    .accessibilityLabel("Use \(name) as a new \(field.label.lowercased())")
            }
            if matches.brands.isEmpty && matches.newName == nil && !brands.isEmpty {
                Text("Nothing matches").font(Typography.secondary).foregroundStyle(Palette.inkFaint)
                    .padding(Metrics.s)
            }
        }
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.inputRadius))
    }

    private func row(_ title: String, detail: String?, isCurrent: Bool, value: String? = nil) -> some View {
        Button {
            save(value ?? title)
        } label: {
            HStack(spacing: Metrics.xs) {
                Text(title).foregroundStyle(Palette.ink)
                if let detail { Text(detail).foregroundStyle(Palette.inkMuted) }
                Spacer(minLength: 0)
                if isCurrent {
                    Image(systemName: "checkmark").foregroundStyle(Palette.beer).accessibilityHidden(true)
                }
            }
            .font(Typography.body)
            .padding(.horizontal, Metrics.s)
            .frame(minHeight: Metrics.minTap)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
        .accessibilityHint("Saves it as the \(field.label.lowercased())")
    }

    private func save(_ name: String) {
        isEditing = false
        draft = name
        guard name != current?.value else { return }
        send(name)
    }
}
