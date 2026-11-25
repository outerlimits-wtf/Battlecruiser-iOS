import Foundation
import Testing
import PubDBModels
@testable import PubDBClient

/// Writes, bodies, rate limits and configuration: what the client needs
/// beyond reading pubs (docs/parity-plan.md, A2).
struct WritingRequestTests {
    private struct Body: Encodable, Sendable {
        let field: String
        let value: String
    }

    private struct Echo: Decodable, Equatable {
        let ok: Bool
    }

    private static let base = URL(string: "https://pubdb.test/api/v1")!

    @Test func aJSONBodyIsEncodedWithItsMethodAndContentType() throws {
        let endpoint = Endpoint(
            method: .post,
            path: ["pubs", "node/1", "contributions"],
            body: .json(Body(field: "guinness_price", value: "620")),
            sendsClock: false
        )
        let request = try #require(endpoint.request(baseURL: Self.base, now: .now))

        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        let sent = try JSONSerialization.jsonObject(with: try #require(request.httpBody)) as? [String: String]
        #expect(sent == ["field": "guinness_price", "value": "620"])
        #expect(request.url?.query == nil)
    }

    @Test func getIsTheDefaultAndSendsNoBody() throws {
        let request = try #require(Endpoint(path: ["meta"], sendsClock: false).request(baseURL: Self.base, now: .now))

        #expect(request.httpMethod == "GET")
        #expect(request.httpBody == nil)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == nil)
    }

    @Test func aMultipartFormEncodesFieldsAndFiles() throws {
        var form = MultipartForm(boundary: "XYZ")
        form.add("kind", value: "pint")
        form.add("photo", file: .init(filename: "photo.jpg", mimeType: "image/jpeg", data: Data("JPEG".utf8)))

        let endpoint = Endpoint(method: .post, path: ["pubs", "node/1", "photos"], body: .multipart(form), sendsClock: false)
        let request = try #require(endpoint.request(baseURL: Self.base, now: .now))
        let body = String(decoding: try #require(request.httpBody), as: UTF8.self)

        #expect(request.value(forHTTPHeaderField: "Content-Type") == "multipart/form-data; boundary=XYZ")
        #expect(body == """
        --XYZ\r
        Content-Disposition: form-data; name="kind"\r
        \r
        pint\r
        --XYZ\r
        Content-Disposition: form-data; name="photo"; filename="photo.jpg"\r
        Content-Type: image/jpeg\r
        \r
        JPEG\r
        --XYZ--\r

        """)
    }

    @Test func tooManyRequestsIsRateLimitedWithTheWaitFromTheHeader() async {
        let body = #"{ "error": { "code": "rate_limited", "message": "Slow down." } }"#
        let transport = FakeTransport(.response(
            status: 429, contentType: "application/json", body: body, headers: ["Retry-After": "17"]
        ))
        let expected = PubDBError.rateLimited(
            retryAfter: 17,
            APIErrorDetail(code: "rate_limited", message: "Slow down.")
        )

        await #expect(throws: expected) {
            let _: Echo = try await PubDBClient.testing(transport).send(Endpoint(path: ["meta"]))
        }
        #expect(expected.userMessage == "Slow down.")
    }

    @Test func aRateLimitWithoutAHeaderOrBodyStillReadsAsRateLimited() async {
        let transport = FakeTransport(.response(status: 429, contentType: "text/plain", body: "no"))

        await #expect(throws: PubDBError.rateLimited(retryAfter: nil, nil)) {
            let _: Echo = try await PubDBClient.testing(transport).send(Endpoint(path: ["meta"]))
        }
    }

    @Test func geoJSONCountsAsJSON() async throws {
        let transport = FakeTransport(.response(status: 200, contentType: "application/geo+json", body: #"{ "ok": true }"#))

        let echo: Echo = try await PubDBClient.testing(transport).send(Endpoint(path: ["pins"]))

        #expect(echo == Echo(ok: true))
    }

    @Test func theBaseURLComesFromInfoPlistWhenSetElseProduction() throws {
        // The test bundle has no PubDBBaseURL key.
        #expect(PubDBClient.configuredBaseURL(in: Bundle(for: BundleToken.self)) == PubDBClient.productionBaseURL)
    }
}

private final class BundleToken {}
