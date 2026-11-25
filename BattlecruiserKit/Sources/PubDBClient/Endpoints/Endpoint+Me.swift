import Foundation

/// `/me` and `/me/avatar`: the signed-in person.
extension Endpoint {
    static let me = Endpoint(path: ["me"], sendsClock: false)

    private struct UsernameBody: Encodable, Sendable {
        let username: String
    }

    static func rename(to username: String) -> Endpoint {
        Endpoint(method: .patch, path: ["me"], body: .json(UsernameBody(username: username)), sendsClock: false)
    }

    static let deleteAccount = Endpoint(method: .delete, path: ["me"], sendsClock: false)

    static func uploadAvatar(_ image: MultipartForm.File) -> Endpoint {
        var form = MultipartForm()
        form.add("avatar", file: image)
        return Endpoint(method: .post, path: ["me", "avatar"], body: .multipart(form), sendsClock: false)
    }

    static let removeAvatar = Endpoint(method: .delete, path: ["me", "avatar"], sendsClock: false)
}
