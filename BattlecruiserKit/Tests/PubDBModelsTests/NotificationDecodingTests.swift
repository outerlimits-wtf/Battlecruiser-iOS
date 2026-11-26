import Foundation
import Testing
@testable import PubDBModels

/// Against the spec's own example (the live endpoint needs an account).
struct NotificationDecodingTests {
    @Test func theInboxAsTheSpecShowsIt() throws {
        let json = #"""
        { "notifications": [
            { "id": 31, "type": "review_liked", "text": "@pint_of_plain liked your review of The Bull",
              "createdAt": "2026-11-25T21:14:00.000Z", "agoLabel": "5 min ago", "read": false,
              "actor": { "username": "pint_of_plain", "label": "@pint_of_plain", "avatarUrl": null },
              "pub": { "id": "node/123456789", "name": "The Bull" }, "reviewId": 49, "photoId": null },
            { "id": 30, "type": "followed", "text": "@x followed you", "createdAt": "…", "agoLabel": "1 h ago",
              "read": true, "actor": { "username": "x", "label": "@x", "avatarUrl": null },
              "pub": null, "reviewId": null, "photoId": null },
            { "id": 29, "type": "something_new", "text": "Something new", "agoLabel": "2 h ago", "read": true }
          ],
          "unread": 1 }
        """#
        let inbox = try JSONDecoder().decode(NotificationInbox.self, from: Data(json.utf8))

        #expect(inbox.unread == 1)
        #expect(inbox.notifications.map(\.id) == [31, 30, 29])
        #expect(inbox.notifications[0].pub?.name == "The Bull")
        #expect(inbox.notifications[1].opensProfile)
        #expect(!inbox.notifications[2].opensProfile)
    }

    @Test func settingsAreWrapped() throws {
        let json = #"{ "settings": { "likes": true, "follows": false, "following": true } }"#
        let settings = try JSONDecoder().decode(NotificationSettingsEnvelope.self, from: Data(json.utf8)).settings
        #expect(!settings.follows)
    }
}
