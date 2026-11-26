import PhotosUI
import SwiftUI
import DesignSystem
import PubDBClient
import PubDBModels

/// "Add a photo", as the web's: pick or take one, say what it shows, an
/// optional caption, the licence, then Upload. The server's message after.
struct PhotoUploadSheet: View {
    let pubID: String
    let context: PanelContext
    let onUploaded: (String) -> Void

    @State private var item: PhotosPickerItem?
    @State private var jpeg: Data?
    @State private var kind: String?
    @State private var caption = ""
    @State private var isUploading = false
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let limits = context.meta?.limits
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.m) {
                HStack {
                    Text("Add a photo").font(Typography.title).foregroundStyle(Palette.ink)
                    Spacer()
                    Button("Cancel") { dismiss() }.foregroundStyle(Palette.inkMuted)
                }
                PhotosPicker(selection: $item, matching: .images) {
                    preview
                }
                .onChange(of: item) { _, picked in load(picked, maxSide: CGFloat(limits?.clientMaxSide ?? 2000)) }
                Text("What is it?").font(Typography.secondary).foregroundStyle(Palette.inkMuted)
                ChipFlow {
                    ForEach(context.meta?.photoKinds ?? []) { option in
                        Button(option.label) { kind = option.key }
                            .buttonStyle(ChipStyle(isSelected: kind == option.key))
                    }
                }
                TextField("Caption (optional)", text: $caption)
                    .padding(Metrics.m)
                    .background(Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: Metrics.inputRadius))
                    .onChange(of: caption) { _, value in
                        let max = limits?.maxCaption ?? 140
                        if value.count > max { caption = String(value.prefix(max)) }
                    }
                Text("No close-ups of people, please. Photos are shared under \(limits?.photoLicense ?? "CC BY-SA 4.0") and credited to your handle.")
                    .font(Typography.secondary)
                    .foregroundStyle(Palette.inkMuted)
                if let error {
                    Text(error).font(Typography.secondary).foregroundStyle(Palette.bad)
                }
                Button(buttonTitle, action: upload)
                    .buttonStyle(ChipStyle(isSelected: true))
                    .disabled(jpeg == nil || kind == nil || isUploading)
            }
            .padding(Metrics.xl)
        }
    }

    private var buttonTitle: String {
        if isUploading { return "Uploading…" }
        return kind == nil ? "Pick what it is" : "Upload"
    }

    @ViewBuilder
    private var preview: some View {
        if let jpeg, let image = UIImage(data: jpeg) {
            Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 220)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius))
                .accessibilityLabel("Chosen photo. Tap to pick another.")
        } else {
            Label("Take or choose a photo", systemImage: "camera")
                .font(Typography.rowTitle)
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: Metrics.cardRadius))
        }
    }

    private func load(_ picked: PhotosPickerItem?, maxSide: CGFloat) {
        guard let picked else { return }
        Task {
            if let data = try? await picked.loadTransferable(type: Data.self) {
                jpeg = ImageUpload.jpeg(from: data, maxSide: maxSide)
            }
        }
    }

    private func upload() {
        guard let jpeg, let kind else { return }
        isUploading = true
        error = nil
        Task {
            defer { isUploading = false }
            do {
                let result = try await context.writer.sendPhoto(to: pubID, jpeg: jpeg, kind: kind, caption: caption)
                onUploaded(result.message ?? "Thanks, it's up.")
                dismiss()
            } catch {
                self.error = PubDBError.wrapping(error)?.userMessage
            }
        }
    }
}
