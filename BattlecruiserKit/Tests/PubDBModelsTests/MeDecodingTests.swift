import Foundation
import Testing
@testable import PubDBModels

struct MeDecodingTests {
    @Test func signedOutAsProductionSendsIt() throws {
        let json = #"{"user":null,"authRequired":true,"session":{"cookiePresent":false,"why":"no-cookie"}}"#
        let me = try JSONDecoder().decode(Me.self, from: Data(json.utf8))

        #expect(me.authRequired)
        #expect(me.user == nil)
        #expect(!me.isInvalidBearer)
    }

    @Test func aBadTokenReadsAsNeedingARefresh() throws {
        let json = #"{"user":null,"authRequired":true,"session":{"cookiePresent":false,"why":"invalid-bearer"}}"#
        #expect(try JSONDecoder().decode(Me.self, from: Data(json.utf8)).isInvalidBearer)
    }

    @Test func signedInWithTheUndocumentedExtras() throws {
        let json = #"""
        {"authRequired":true,"user":{"id":"workos:user_1","username":"goatloaf","label":"@goatloaf",
         "usernameChosen":true,"contributions":12,"admin":false,"avatarUrl":"https://x.test/a.webp","visited":3,"reviews":2}}
        """#
        let user = try #require(try JSONDecoder().decode(Me.self, from: Data(json.utf8)).user)

        #expect(user.label == "@goatloaf")
        #expect(user.visited == 3)
        #expect(user.avatarURL != nil)
    }
}
