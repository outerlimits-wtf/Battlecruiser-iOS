import SwiftUI
import UIKit
import DesignSystem
import PubDBModels

/// `text`, `url`, `phone`, and any kind this build doesn't know (the spec
/// says plain text): a box prefilled with the current value, so a typo is a
/// fix rather than a retype, and nothing to send until it differs.
struct TextValueEditor: View {
    let field: ContributableField
    let current: EditableValue?
    let send: (String) -> Void

    @State private var draft = ""

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Metrics.s) {
            TextField(field.placeholder ?? field.label, text: $draft, axis: isFreeText ? .vertical : .horizontal)
                .lineLimit(isFreeText ? 1...4 : 1...1)
                .font(Typography.body)
                .keyboardType(keyboard)
                .textInputAutocapitalization(isFreeText ? .sentences : .never)
                .autocorrectionDisabled(!isFreeText)
                .submitLabel(.done)
                .onSubmit(save)
                .accessibilityLabel(field.label)
            Button("Save", action: save)
                .buttonStyle(ChipStyle(isSelected: canSave))
                .disabled(!canSave)
                .accessibilityHint("Sends the new \(field.label.lowercased())")
        }
        .padding(Metrics.s)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.inputRadius))
        .onAppear { draft = current?.value ?? "" }
        // A saved value comes back in the pub; show that rather than the draft.
        .onChange(of: current?.value) { _, value in draft = value ?? "" }
        .onChange(of: draft) { _, value in
            if let max = field.maxLength, value.count > max { draft = String(value.prefix(max)) }
        }
    }

    private var trimmed: String { draft.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var canSave: Bool { !trimmed.isEmpty && trimmed != current?.value }

    private func save() {
        guard canSave else { return }
        send(trimmed)
    }

    private var isFreeText: Bool {
        switch field.kind {
        case .url, .phone: false
        default: true
        }
    }

    private var keyboard: UIKeyboardType {
        switch field.kind {
        case .url: .URL
        case .phone: .phonePad
        default: .default
        }
    }
}
