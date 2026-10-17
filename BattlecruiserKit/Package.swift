// swift-tools-version: 6.2
import PackageDescription

// Battlecruiser's modules (decision D24). The app target only wires these
// together. Modules are added here as each one is built; the planned set and
// their dependencies are in docs/mvp-plan.md ("Modules"). Dependencies only
// point downwards: features → design system / client / cache → models.
//
// Non-UI modules keep Swift's default (nonisolated) so decoding and networking
// stay off the main actor. UI modules, when added, set
// `.defaultIsolation(MainActor.self)` to match the app target.
let package = Package(
    name: "BattlecruiserKit",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "PubDBModels", targets: ["PubDBModels"]),
        .library(name: "PubDBClient", targets: ["PubDBClient"]),
        .library(name: "UserLocation", targets: ["UserLocation"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "PubsFeature", targets: ["PubsFeature"]),
        .library(name: "PubDetailFeature", targets: ["PubDetailFeature"]),
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
        .target(name: "PubDBClient", dependencies: ["PubDBModels"]),
        .testTarget(name: "PubDBClientTests", dependencies: ["PubDBClient", "PubDBModels"]),

        /// Location permission and the user's current position. UI-facing state, so main actor.
        .target(name: "UserLocation", swiftSettings: [.defaultIsolation(MainActor.self)]),
        .testTarget(name: "UserLocationTests", dependencies: ["UserLocation"]),

        /// Shared SwiftUI building blocks: the ship pin, and later the open pill,
        /// freshness label and attribution footer.
        .target(
            name: "DesignSystem",
            dependencies: ["PubDBModels"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem", "PubDBModels"]),

        /// The pubs around the user: state that follows the map, then the map and list views.
        .target(
            name: "PubsFeature",
            dependencies: ["PubDBClient", "PubDBModels", "DesignSystem", "UserLocation", "PubDetailFeature"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(name: "PubsFeatureTests", dependencies: ["PubsFeature", "PubDBClient", "PubDBModels"]),

        /// One pub in full: the selected pub's state, then the detail sheet.
        .target(
            name: "PubDetailFeature",
            dependencies: ["PubDBClient", "PubDBModels", "DesignSystem"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(name: "PubDetailFeatureTests", dependencies: ["PubDetailFeature", "PubDBClient", "PubDBModels"]),
    ],
    swiftLanguageModes: [.v5]
)
