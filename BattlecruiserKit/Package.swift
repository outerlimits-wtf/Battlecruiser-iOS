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
    ],
    swiftLanguageModes: [.v5]
)
