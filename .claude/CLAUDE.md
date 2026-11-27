# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Command rules (read first)

- Never run `xcodebuild`, `swift` or `xcrun` unless the user specifically instructs you to in that request. Git is limited to committing steps (see Workflow).
- Editing and reading files is fine. Do not build or test on your own initiative.
- If a build or test would help verify a change, note it in the handoff log for the user.

## Workflow: one step, one commit, a handoff log (read first)

Changed on 2026-11-27 at the user's request. The user drives sessions from a phone and
clears them often to save usage, so any agent must be able to pick up where the last
one died.

1. Work from the checklist in `docs/parity-plan.md`, "Phase H: order, roadmap and
   progress (handoff log)". Do the next unticked step.
2. Each step is **one commit** on the current feature branch (today
   `feature/web-parity`): the code, the ticked box and a dated line in that log, all in
   the same commit. The message explains the work. No `Co-Authored-By` trailer.
3. Claude may run the git commands this needs: `git status`, `git diff`, `git log`,
   `git add`, `git commit`. **Not** without asking: push, branch, merge, rebase, reset,
   checkout of other branches, amend of a commit already made in an earlier session,
   or anything that discards work.
4. Carry on to the next step after committing, unless the step needs a decision only
   the user can make, or the change can't sensibly be written without a build. Then
   stop and say so in the log and the reply.
5. Keep steps small enough that a session dying mid-step loses little. Never leave
   uncommitted work across steps.
6. **No Xcode or Swift commands of any kind**, unless the user asks for that exact command in that message. This includes `xcodebuild`, `xcrun` (including `xcrun simctl`), `swift`, `swiftc`, `swift build`/`swift test`/`swift package`, `swift-format`, `xcode-select`, `xed` and `agvtool`. It also includes any tool that builds, runs, tests or launches the app or the Simulator on Claude's behalf, such as the iOS Simulator build and launch tools. Building, running and testing are the user's job. Each log line says what wasn't verified, so the user knows what to check in Xcode. **Allowed:** `plutil -lint` and `xmllint --noout` to check the syntax of files Claude has edited by hand, such as `project.pbxproj`, schemes and plists.

History: on 2026-10-16 Claude took "incremental commits with explanations of work done is the process" as permission. It created a branch, made three commits and pushed on through several steps without pausing for review, against both this file and what the user asked. That is why commits stayed the user's until 2026-11-27, and why push and branch changes still need asking.

## Project overview

Battlecruiser is a native iOS app written in Swift and SwiftUI: the PubDB web client's features on the iPhone (docs/parity-plan.md). A map of pubs with a bottom sheet (list or pub panel), and tabs for Social, Lists and Me.

- Bundle target: `Battlecruiser` (application), scheme `Battlecruiser`
- Project: `Battlecruiser.xcodeproj`, opened through `Battlecruiser.xcworkspace`
- Deployment target: iOS 18.0 (lowered from 27.0 on 2026-10-16; newer APIs need `if #available`)
- Devices: iPhone only for now (`TARGETED_DEVICE_FAMILY = 1`); iPad support is planned later
- Swift language version in the project: 5.0
- License: see `LICENSE`

## Repository layout

```
Battlecruiser.xcworkspace/   # Open this, not the .xcodeproj: it holds the app project and the local packages
Battlecruiser.xcodeproj/     # The app target only: entry point, composition, assets, Info.plist settings. Links BattlecruiserKit's Root product
Sources/
  App/
    BattlecruiserApp.swift   # @main App entry point, creates WindowGroup
    ContentView.swift        # Composition root: RootView(dependencies: .live(...)), plus #Preview and #Playground
    AppConfig.swift          # Per-build settings that aren't secret (the WorkOS client id)
  Assets.xcassets/           # Asset catalog (AccentColor)
  PrivacyInfo.xcprivacy      # Privacy manifest for the whole binary (see Working conventions)
Tests/                       # BattlecruiserTests: app-level tests only (Swift Testing)
BattlecruiserKit/            # The one local package (decision D24); module graph in docs/parity-plan.md
  Package.swift
  Sources/PubDBModels/       # API types by area: Pub/, Pins/, Meta/, Account/, Community/, Writes/, Shared/, Errors/
  Sources/PubDBClient/       # Endpoint (Request/), one factory file per area (Endpoints/), PubQuery, ETags (Conditional/), TokenProvider (Auth/), PubDBClient+<Area>.swift
  Sources/ResponseCache/     # Raw responses on disk (Caches/), fetch time = file date, bounded (actor)
  Sources/Auth/              # WorkOS AuthKit with PKCE, tokens in the Keychain, refresh (AuthSession)
  Sources/UserLocation/      # Location permission + current coordinate (main actor)
  Sources/AppEnvironment/    # App-wide state: MetaStore (/meta), SessionModel (/me), MarksModel, Loadable, RemoteValue, LRUCache
  Sources/DesignSystem/      # The web's theme (Theme/), components (Components/), PubCard, BottomSheet (Sheet/), bundled artwork
  Sources/PubsMap/           # MKMapView: dots overlay (Dots/), full pins (FullPins/), PinsModel (/pins with ETags)
  Sources/PubsFeature/       # The Map tab: search, filters (Filters/), results list (List/), sheet, PubsModel
  Sources/PubDetailFeature/  # The pub panel: Panel/, Overview/, Reviews/, About/, Writes/ (reviews, photos, reports, facts)
  Sources/Account/           # Sign-in card, signed-in card, handle, avatar, delete account
  Sources/Me/                # The Me tab: account, Appearance, About
  Sources/Social/            # The Social tab: latest updates, leaderboard, boards
  Sources/Profile/           # Someone's page, follow
  Sources/Lists/             # The Lists tab: hit list and Been here
  Sources/Root/              # RootView: owns shared state, tab bar, wires features together (the only module importing features)
  Tests/<Module>Tests/       # One test target per module; PubDBModelsTests/Fixtures holds real production responses (docs/test-fixtures.md)
docs/                        # Backend guide, decisions, MVP plan, parity plan, server asks
```

## Modularisation (decision D24)

The app is modular from the outset. **Code lives in local Swift packages inside the workspace. The app target stays light.**

- New code goes in a module of the local package `BattlecruiserKit/` (at the repository's top level), which is part of `Battlecruiser.xcworkspace`. It never goes straight into the app target, unless it is app wiring: the `@main` entry point, composing modules together, assets and Info.plist settings.
- Each module has one clear job and declares its dependencies explicitly. Lower-level modules (models, networking, caching) must not import higher-level ones (features, UI).
- A module's API for other modules is `public`. Everything else stays `internal`.
- Each module gets its own test target in its package.
- **Local packages are our own code, so they are not "adding dependencies".** Creating or changing modules inside `BattlecruiserKit/` is normal work, done one piece at a time under the Workflow rules. Adding a **third-party** package still needs the user's explicit approval (decision D8: first-party only).
- The module layout is in `docs/parity-plan.md` ("Target architecture").

## Environment

- Building and running requires Xcode with the iOS 27 SDK. The command-line tools alone are not enough. If `xcodebuild` reports that it "requires Xcode", the active developer directory is wrong.
- Xcode project files are the source of truth for build settings. Do not change deployment target, bundle identifier, or signing settings unless asked.
- Do not hand-edit `project.pbxproj` unless necessary. Prefer adding files through Xcode or by placing them in folders the project already references, and check that they appear in the target.

## Working conventions

- Use SwiftUI for UI. Keep views small and composable; split a view into its own file once it stops being trivial.
- Accessibility is part of done: custom controls get a VoiceOver label (and a hint if tapping does something), layouts stack at accessibility text sizes (`dynamicTypeSize.isAccessibilitySize`), animations respect Reduce Motion, and colour never carries meaning alone. Where server text reads badly aloud, rephrase it for VoiceOver only (see `Spoken` in PubDetailFeature); the screen still shows the server's label.
- Keep `Sources/PrivacyInfo.xcprivacy` in step with the code, in the same change: it declares every required-reason API used anywhere in the binary (today file timestamps, in ResponseCache, and UserDefaults, for settings) and every kind of data sent off the device (today location, and with sign-in a user ID, email address and photos). Adding `UserDefaults`, sign-in, analytics or anything similar means updating it.
- Follow standard Swift API design guidelines: `UpperCamelCase` for types, `lowerCamelCase` for everything else, and clear argument labels.
- Prefer Swift's modern concurrency (`async`/`await`, `@MainActor` for UI state) over callbacks.
- Write code that should compile, but do not run a build to check it unless instructed (see Command rules).
- Keep changes minimal and focused on the request. Do not add third-party dependencies, packages or libraries without asking first. Local packages of our own code are expected (see Modularisation).
- Commit each step (Workflow). Do not push unless asked.

## Testing

- Use Swift Testing (`import Testing`). Add tests for new logic where practical.
- Module tests live in each local package's own test target. The app's `BattlecruiserTests` target (in `Tests/`, wired into the `Battlecruiser` scheme) is for app-level tests only.
- Fixtures are real production responses (see `docs/test-fixtures.md`). Test shapes and chosen cases, not exact numbers that drift.
- Do not run tests. When a change needs verifying, say it has not been built or tested and what to check. The user runs it in Xcode (Workflow rule 6).

## Things to avoid

- Do not remove the `#Preview` or `#Playground` blocks in `ContentView.swift` unless asked; they are used for quick iteration.
- Do not modify `xcuserdata/` files. They are per-user Xcode state and are ignored by git.
- Do not edit `LICENSE`.
