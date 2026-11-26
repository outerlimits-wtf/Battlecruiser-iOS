import UIKit
import PubDBClient

/// Turns a picked image into an upload the server accepts: JPEG (never HEIC),
/// no longer than `maxSide` on its long side.
public enum ImageUpload {
    public static func jpeg(from data: Data, maxSide: CGFloat, name: String) -> MultipartForm.File? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let jpeg = resized.jpegData(compressionQuality: 0.86) else { return nil }
        return MultipartForm.File(filename: name, mimeType: "image/jpeg", data: jpeg)
    }
}
