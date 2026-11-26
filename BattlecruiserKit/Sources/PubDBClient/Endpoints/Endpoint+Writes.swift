import Foundation

/// Contributions, reviews and reports.
extension Endpoint {
    private struct ContributionBody: Encodable, Sendable {
        let field: String
        let value: String
    }

    private struct ReviewBody: Encodable, Sendable {
        let rating: Int
        let body: String?
    }

    private struct ReportBody: Encodable, Sendable {
        let type: String
        let id: String
        let reason: String
        let note: String?
    }

    static func contribute(to pubID: String, field: String, value: String) -> Endpoint {
        Endpoint(method: .post, path: ["pubs", pubID, "contributions"],
                 body: .json(ContributionBody(field: field, value: value)), sendsClock: false)
    }

    static func removeContribution(_ id: Int, from pubID: String) -> Endpoint {
        Endpoint(method: .delete, path: ["pubs", pubID, "contributions", String(id)], sendsClock: false)
    }

    static func review(_ pubID: String, rating: Int, body: String?) -> Endpoint {
        Endpoint(method: .post, path: ["pubs", pubID, "reviews"],
                 body: .json(ReviewBody(rating: rating, body: body)), sendsClock: false)
    }

    static func removeReview(_ id: Int, from pubID: String) -> Endpoint {
        Endpoint(method: .delete, path: ["pubs", pubID, "reviews", String(id)], sendsClock: false)
    }

    static func report(type: String, id: String, reason: String, note: String?) -> Endpoint {
        Endpoint(method: .post, path: ["reports"],
                 body: .json(ReportBody(type: type, id: id, reason: reason, note: note)), sendsClock: false)
    }
}

extension Endpoint {
    static func uploadPhoto(to pubID: String, image: MultipartForm.File, kind: String, caption: String?) -> Endpoint {
        var form = MultipartForm()
        form.add("photo", file: image)
        form.add("kind", value: kind)
        if let caption, !caption.isEmpty { form.add("caption", value: caption) }
        return Endpoint(method: .post, path: ["pubs", pubID, "photos"], body: .multipart(form), sendsClock: false)
    }
}

extension Endpoint {
    static func like(_ reviewID: Int, on pubID: String, _ on: Bool) -> Endpoint {
        Endpoint(method: on ? .put : .delete, path: ["pubs", pubID, "reviews", String(reviewID), "like"], sendsClock: false)
    }
}
