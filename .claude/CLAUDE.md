# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Command rules (read first)

- Never run `xcodebuild`, `swift`, `xcrun`, or any `git` command unless the user specifically instructs you to in that request.
- Editing and reading files is fine. Do not build, test, or inspect git state on your own initiative.
- If a build or test would help verify a change, say so and ask the user to run it or to give the go-ahead.

## Workflow: pause after every piece of work (read first)

The user reviews, builds, tests and commits every change themselves. Claude's job ends at edited files.

1. Do **one** piece of work at a time: one plan step, or one milestone sub-step, never several in a row.
2. When it is done, **stop**. Summarise what changed (the files, and why), say what has not been verified, and give a **suggested commit message** that explains the work.
3. **Wait for the user's explicit approval** before starting the next piece. "Carry on", "continue" or "that's the process" approve the *next single piece*, not a run of several.
4. **No git commands of any kind**: no commits, no branches, no `git status`, `git log`, `git diff`, `git mv`. Not even to undo a mistake, unless the user asks for that exact action in that message. If git matters, ask the user or give them the commands to run. Use plain file operations (Write, Edit, `mv`) for moving files.
5. Wording like "incremental commits are the process" describes **the user's** commits. It is never permission for Claude to commit.
6. **No Xcode or Swift commands of any kind**, unless the user asks for that exact command in that message. This includes `xcodebuild`, `xcrun` (including `xcrun simctl`), `swift`, `swiftc`, `swift build`/`swift test`/`swift package`, `swift-format`, `xcode-select`, `xed` and `agvtool`. It also includes any tool that builds, runs, tests or launches the app or the Simulator on Claude's behalf, such as the iOS Simulator build and launch tools. Building, running and testing are the user's job. When verification would help, say what should be checked, and the user will do it in Xcode. **Allowed:** `plutil -lint` and `xmllint --noout` to check the syntax of files Claude has edited by hand, such as `project.pbxproj`, schemes and plists.

Why this exists: on 2026-10-16 Claude took "incremental commits with explanations of work done is the process" as permission. It created a branch, made three commits and pushed on through several steps without pausing for review, against both this file and what the user asked.

## Project overview

Battlecruiser is a native iOS app written in Swift and SwiftUI. It is at an early stage: the app currently shows a placeholder `ContentView` ("Hello, world!").

- Bundle target: `Battlecruiser` (application), scheme `Battlecruiser`
- Project: `Battlecruiser.xcodeproj`, opened through `Battlecruiser.xcworkspace`
- Deployment target: iOS 18.0 (lowered from 27.0 on 2026-10-16; newer APIs need `if #available`)
- Devices: iPhone only for now (`TARGETED_DEVICE_FAMILY = 1`); iPad support is planned later
- Swift language version in the project: 5.0
- License: see `LICENSE`

## Repository layout

```
Battlecruiser.xcworkspace/   # Open this, not the .xcodeproj: it holds the app project and the local packages
Battlecruiser.xcodeproj/     # The app target only: entry point, composition, assets, Info.plist settings. Links BattlecruiserKit's products (PubDBClient, PubsFeature)
Sources/
  App/
    BattlecruiserApp.swift   # @main App entry point, creates WindowGroup
    ContentView.swift        # Composition root: PubsMapScreen(source: PubDBClient.live()), plus #Preview and #Playground
  Assets.xcassets/           # Asset catalog (AccentColor)
  PrivacyInfo.xcprivacy      # Privacy manifest for the whole binary (see Working conventions)
Tests/                       # BattlecruiserTests: app-level tests only (Swift Testing)
BattlecruiserKit/            # The one local package (decision D24), at the top level; modules added as they are built
  Package.swift
  Sources/PubDBModels/       # API response types
  Sources/PubDBClient/       # Talks to the v1 API: requests, response checks, PubDBError; saves/reads responses via ResponseCache; live() for the app
  Sources/ResponseCache/     # Raw responses on disk (Caches/), fetch time = file date, bounded (actor)
  Sources/UserLocation/      # Location permission + current coordinate (main actor)
  Sources/DesignSystem/      # Shared SwiftUI pieces: ShipPin, OpenPill, FreshnessLabel, PinEmphasis + its tint (main actor)
  Sources/PubsFeature/       # PubsMapScreen (Map/List switch) + PubMap (MapKit, tappable pins), PubListView + PubRow, PubsModel, PubOrdering, Freshness (stale/refresh rules), PubsNotice (outside London / offline / failed / empty) (main actor)
  Sources/PubDetailFeature/  # PubDetailModel (selected pub: instant summary, cached + fresh detail) + PubDetailSheet and its Sections/ (main actor)
  Tests/PubDBModelsTests/    # Decoding tests + Fixtures/ (real production responses; docs/test-fixtures.md)
  Tests/PubDBClientTests/    # Request-building and error tests against a fake transport
  Tests/ResponseCacheTests/  # Store/load/evict tests in a temporary folder
  Tests/UserLocationTests/   # Permission-flow tests against a fake location manager
  Tests/DesignSystemTests/   # Pin emphasis rules
  Tests/PubsFeatureTests/    # Ordering + PubsModel timing/error tests against a fake PubSource
  Tests/PubDetailFeatureTests/ # PubDetailModel tests against a fake PubDetailSource
docs/                        # Backend guide, decisions, MVP plan
```

## Modularisation (decision D24)

The app is modular from the outset. **Code lives in local Swift packages inside the workspace. The app target stays light.**

- New code goes in a module of the local package `BattlecruiserKit/` (at the repository's top level), which is part of `Battlecruiser.xcworkspace`. It never goes straight into the app target, unless it is app wiring: the `@main` entry point, composing modules together, assets and Info.plist settings.
- Each module has one clear job and declares its dependencies explicitly. Lower-level modules (models, networking, caching) must not import higher-level ones (features, UI).
- A module's API for other modules is `public`. Everything else stays `internal`.
- Each module gets its own test target in its package.
- **Local packages are our own code, so they are not "adding dependencies".** Creating or changing modules inside `BattlecruiserKit/` is normal work, done one piece at a time under the Workflow rules. Adding a **third-party** package still needs the user's explicit approval (decision D8: first-party only).
- The module layout is in `docs/mvp-plan.md` ("Modules").

## Environment

- Building and running requires Xcode with the iOS 27 SDK. The command-line tools alone are not enough. If `xcodebuild` reports that it "requires Xcode", the active developer directory is wrong.
- Xcode project files are the source of truth for build settings. Do not change deployment target, bundle identifier, or signing settings unless asked.
- Do not hand-edit `project.pbxproj` unless necessary. Prefer adding files through Xcode or by placing them in folders the project already references, and check that they appear in the target.

## Working conventions

- Use SwiftUI for UI. Keep views small and composable; split a view into its own file once it stops being trivial.
- Accessibility is part of done: custom controls get a VoiceOver label (and a hint if tapping does something), layouts stack at accessibility text sizes (`dynamicTypeSize.isAccessibilitySize`), animations respect Reduce Motion, and colour never carries meaning alone. Where server text reads badly aloud, rephrase it for VoiceOver only (see `Spoken` in PubDetailFeature); the screen still shows the server's label.
- Keep `Sources/PrivacyInfo.xcprivacy` in step with the code, in the same change: it declares every required-reason API used anywhere in the binary (today only file timestamps, in ResponseCache) and every kind of data sent off the device (today only location, to the PubDB API). Adding `UserDefaults`, sign-in, analytics or anything similar means updating it.
- Follow standard Swift API design guidelines: `UpperCamelCase` for types, `lowerCamelCase` for everything else, and clear argument labels.
- Prefer Swift's modern concurrency (`async`/`await`, `@MainActor` for UI state) over callbacks.
- Write code that should compile, but do not run a build to check it unless instructed (see Command rules).
- Keep changes minimal and focused on the request. Do not add third-party dependencies, packages or libraries without asking first. Local packages of our own code are expected (see Modularisation).
- Do not commit or push unless asked.

## Testing

- Use Swift Testing (`import Testing`). Add tests for new logic where practical.
- Module tests live in each local package's own test target. The app's `BattlecruiserTests` target (in `Tests/`, wired into the `Battlecruiser` scheme) is for app-level tests only.
- Fixtures are real production responses (see `docs/test-fixtures.md`). Test shapes and chosen cases, not exact numbers that drift.
- Do not run tests. When a change needs verifying, say it has not been built or tested and what to check. The user runs it in Xcode (Workflow rule 6).

## Things to avoid

- Do not remove the `#Preview` or `#Playground` blocks in `ContentView.swift` unless asked; they are used for quick iteration.
- Do not modify `xcuserdata/` files. They are per-user Xcode state and are ignored by git.
- Do not edit `LICENSE`.
