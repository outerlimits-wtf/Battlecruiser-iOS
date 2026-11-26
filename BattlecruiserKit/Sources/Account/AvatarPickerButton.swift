import PhotosUI
import SwiftUI
import AppEnvironment
import DesignSystem

/// "Add photo" / "Change photo" for the profile picture, and "Remove" when
/// there is one (which the web lacks). The picture is shrunk to a JPEG first.
struct AvatarPickerButton: View {
    let session: SessionModel
    let hasAvatar: Bool
    @State private var item: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $item, matching: .images) {
            Text(hasAvatar ? "Change photo" : "Add photo")
        }
        .buttonStyle(ChipStyle())
        .onChange(of: item) { _, picked in
            guard let picked else { return }
            Task {
                if let data = try? await picked.loadTransferable(type: Data.self),
                   let file = ImageUpload.jpeg(from: data, maxSide: 512, name: "avatar.jpg") {
                    await session.setAvatar(file)
                }
                item = nil
            }
        }
        if hasAvatar {
            Button("Remove photo") { Task { await session.removeAvatar() } }
                .buttonStyle(ChipStyle())
        }
    }
}
