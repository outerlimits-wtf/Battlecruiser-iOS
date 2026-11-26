import SwiftUI
import AppEnvironment
import DesignSystem

/// Change the handle. The server decides what's allowed and says why not.
struct HandleEditor: View {
    let session: SessionModel
    @State private var handle: String
    @Environment(\.dismiss) private var dismiss

    /// The longest handle the server takes (S13 asks for this in /meta).
    static let maxLength = 22

    init(session: SessionModel, current: String) {
        self.session = session
        _handle = State(initialValue: current)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.m) {
            Text("Your handle").font(Typography.title).foregroundStyle(Palette.ink)
            HStack(spacing: 2) {
                Text("@").foregroundStyle(Palette.inkMuted)
                TextField("handle", text: $handle)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: handle) { _, value in
                        if value.count > Self.maxLength { handle = String(value.prefix(Self.maxLength)) }
                    }
            }
            .font(.body)
            .padding(Metrics.m)
            .background(Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: Metrics.inputRadius))
            Text("Lowercase, numbers and underscores. It goes on everything you add.")
                .font(Typography.secondary)
                .foregroundStyle(Palette.inkMuted)
            if let message = session.message {
                Text(message).font(Typography.secondary).foregroundStyle(Palette.bad)
            }
            HStack {
                Button("Cancel") { dismiss() }.buttonStyle(ChipStyle())
                Spacer()
                Button(session.isWorking ? "Saving…" : "Save") {
                    Task {
                        if await session.rename(to: handle) { dismiss() }
                    }
                }
                .buttonStyle(ChipStyle(isSelected: true))
                .disabled(session.isWorking || handle.isEmpty)
            }
        }
        .padding(Metrics.xl)
        .presentationDetents([.medium])
    }
}
