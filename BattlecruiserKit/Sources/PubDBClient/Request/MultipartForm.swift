import Foundation

/// A `multipart/form-data` body, for `POST /pubs/{id}/photos` and
/// `POST /me/avatar`. Built by hand because Foundation has no encoder for it.
public struct MultipartForm: Sendable, Equatable {
    public struct File: Sendable, Equatable {
        public var filename: String
        public var mimeType: String
        public var data: Data

        public init(filename: String, mimeType: String, data: Data) {
            self.filename = filename
            self.mimeType = mimeType
            self.data = data
        }
    }

    enum Part: Sendable, Equatable {
        case field(name: String, value: String)
        case file(name: String, File)
    }

    let boundary: String
    private(set) var parts: [Part] = []

    public init(boundary: String = "pubdb-\(UUID().uuidString)") {
        self.boundary = boundary
    }

    public mutating func add(_ name: String, value: String) {
        parts.append(.field(name: name, value: value))
    }

    public mutating func add(_ name: String, file: File) {
        parts.append(.file(name: name, file))
    }

    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    func encoded() -> Data {
        var data = Data()
        for part in parts {
            data.append("--\(boundary)\r\n")
            switch part {
            case .field(let name, let value):
                data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
                data.append(value)
            case .file(let name, let file):
                data.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(file.filename)\"\r\n")
                data.append("Content-Type: \(file.mimeType)\r\n\r\n")
                data.append(file.data)
            }
            data.append("\r\n")
        }
        data.append("--\(boundary)--\r\n")
        return data
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
