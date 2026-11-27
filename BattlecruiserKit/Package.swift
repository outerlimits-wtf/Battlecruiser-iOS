// swift-tools-version: 6.2
import PackageDescription

// Battlecruiser's modules (decision D24). The app target only wires these
// together. Modules are added here as each one is built; the planned set and
// their dependencies are in docs/parity-plan.md ("Target architecture"). Dependencies only
// point downwards: features → design system / client / cache → models.
//
// Non-UI modules keep Swift's default (nonisolated) so decoding and networking
// stay off the main actor. UI modules set `.defaultIsolation(MainActor.self)`
// to match the app target.
let package = Package(
    name: "BattlecruiserKit",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "PubDBModels", targets: ["PubDBModels"]),
        .library(name: "PubDBClient", targets: ["PubDBClient"]),
        .library(name: "ResponseCache", targets: ["ResponseCache"]),
        .library(name: "Auth", targets: ["Auth"]),
        .library(name: "UserLocation", targets: ["UserLocation"]),
        .library(name: "AppEnvironment", targets: ["AppEnvironment"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "PubsMap", targets: ["PubsMap"]),
        .library(name: "PubsFeature", targets: ["PubsFeature"]),
        .library(name: "PubDetailFeature", targets: ["PubDetailFeature"]),
        .library(name: "Account", targets: ["Account"]),
        .library(name: "Me", targets: ["Me"]),
        .library(name: "Social", targets: ["Social"]),
        .library(name: "Profile", targets: ["Profile"]),
        .library(name: "Lists", targets: ["Lists"]),
        .library(name: "Root", targets: ["Root"]),
    ],
    targets: [
        /// The PubDB v1 API's response types. Foundation only.
        .target(name: "PubDBModels"),
        .testTarget(
            name: "PubDBModelsTests",
            dependencies: ["PubDBModels"],
            resources: [.copy("Fixtures")]
        ),

        /// Talks to the PubDB v1 API: builds requests, checks responses, maps errors.
        .target(name: "PubDBClient", dependencies: ["PubDBModels", "ResponseCache"]),
        .testTarget(name: "PubDBClientTests", dependencies: ["PubDBClient", "PubDBModels", "ResponseCache"]),

        /// Signing in: WorkOS AuthKit with PKCE, tokens in the Keychain, refreshed
        /// on a 401. Provides the client's TokenProvider. Not UI.
        .target(name: "Auth", dependencies: ["PubDBClient"]),
        .testTarget(name: "AuthTests", dependencies: ["Auth", "PubDBClient"]),

        /// Raw server responses on disk, with the time they were fetched. Foundation only.
        .target(name: "ResponseCache"),
        .testTarget(name: "ResponseCacheTests", dependencies: ["ResponseCache"]),

        /// Location permission and the user's current position. UI-facing state, so main actor.
        .target(name: "UserLocation", swiftSettings: [.defaultIsolation(MainActor.self)]),
        .testTarget(name: "UserLocationTests", dependencies: ["UserLocation"]),

        /// App-wide state every feature reads: the server's lists (/meta), who is
        /// signed in (/me), and the shared loading plumbing. Main actor.
        .target(
            name: "AppEnvironment",
            dependencies: ["Auth", "PubDBClient", "PubDBModels"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(name: "AppEnvironmentTests", dependencies: ["AppEnvironment", "Auth", "PubDBClient", "PubDBModels"]),

        /// Shared SwiftUI building blocks: pins, pills, labels.
        .target(
            name: "DesignSystem",
            dependencies: ["PubDBModels"],
            resources: [.process("Resources")],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem", "PubDBModels"]),

        /// The map: every pin (/pins, ETag, once a minute), drawn as dots zoomed
        /// out and full pins zoomed in.
        .target(
            name: "PubsMap",
            dependencies: ["PubDBClient", "PubDBModels", "DesignSystem"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(name: "PubsMapTests", dependencies: ["PubsMap", "PubDBClient", "PubDBModels"]),

        /// The pubs around the user: state that follows the map, then the map and list views.
        .target(
            name: "PubsFeature",
            dependencies: ["PubDBClient", "PubDBModels", "AppEnvironment", "DesignSystem", "PubsMap"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(name: "PubsFeatureTests", dependencies: ["PubsFeature", "PubDBClient", "PubDBModels"]),

        /// One pub in full: the selected pub's state, then the detail sheet.
        .target(
            name: "PubDetailFeature",
            dependencies: ["PubDBClient", "PubDBModels", "AppEnvironment", "DesignSystem"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(name: "PubDetailFeatureTests", dependencies: ["PubDetailFeature", "PubDBClient", "PubDBModels"]),

        /// The account: sign in, the signed-in card, handle, picture, sign out,
        /// delete account.
        .target(
            name: "Account",
            dependencies: ["AppEnvironment", "Auth", "DesignSystem", "PubDBClient", "PubDBModels"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),

        /// The Me tab: the account, appearance, and About.
        .target(
            name: "Me",
            dependencies: ["Account", "AppEnvironment", "DesignSystem"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),

        /// The Social tab: latest updates, the leaderboard, the boards.
        .target(
            name: "Social",
            dependencies: ["AppEnvironment", "DesignSystem", "PubDBClient", "PubDBModels"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),

        /// Someone's page: stats, coverage, reviews, pubs, follow.
        .target(
            name: "Profile",
            dependencies: ["AppEnvironment", "DesignSystem", "PubDBClient", "PubDBModels"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),

        /// The Lists tab: the hit list and Been here.
        .target(
            name: "Lists",
            dependencies: ["AppEnvironment", "DesignSystem", "PubDBClient", "PubDBModels"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),

        /// The whole app: owns shared state and wires the features together, so
        /// features never import each other. The only module that imports features.
        .target(
            name: "Root",
            dependencies: [
                "Account", "AppEnvironment", "Auth", "DesignSystem", "Lists", "Me", "Profile", "PubDBClient", "PubDBModels", "Social",
                "PubDetailFeature", "PubsFeature", "PubsMap", "UserLocation",
            ],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
    ],
    swiftLanguageModes: [.v5]
)
