# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Command rules (read first)

- Never run `xcodebuild`, `swift`, `xcrun`, or any `git` command unless the user specifically instructs you to in that request.
- Editing and reading files is fine. Do not build, test, or inspect git state on your own initiative.
- If a build or test would help verify a change, say so and ask the user to run it or to give the go-ahead.

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
Sources/
  MyApp.swift          # @main App entry point, creates WindowGroup
  ContentView.swift    # Root view, plus #Preview and #Playground
  Assets.xcassets/     # Asset catalog (AccentColor)
Tests/                 # Test target location; currently empty
Battlecruiser.xcodeproj/
Battlecruiser.xcworkspace/
```

Keep new source files under `Sources/` and new tests under `Tests/`.

## Environment

- Building and running requires Xcode with the iOS 27 SDK. The command-line tools alone are not enough. If `xcodebuild` reports that it "requires Xcode", the active developer directory is wrong.
- Xcode project files are the source of truth for build settings. Do not change deployment target, bundle identifier, or signing settings unless asked.
- Do not hand-edit `project.pbxproj` unless necessary. Prefer adding files through Xcode or by placing them in folders the project already references, and check that they appear in the target.

## Working conventions

- Use SwiftUI for UI. Keep views small and composable; split a view into its own file once it stops being trivial.
- Follow standard Swift API design guidelines: `UpperCamelCase` for types, `lowerCamelCase` for everything else, and clear argument labels.
- Prefer Swift's modern concurrency (`async`/`await`, `@MainActor` for UI state) over callbacks.
- Write code that should compile, but do not run a build to check it unless instructed (see Command rules).
- Keep changes minimal and focused on the request. Do not add dependencies, Swift packages, or third-party libraries without asking first.
- Do not commit or push unless asked.

## Testing

- Put unit tests in `Tests/`. Add tests for new logic where practical.
- There is no test target in the project yet, so the scheme's test action has nothing to run. If you add tests, add the test target in Xcode and make sure it is wired into the `Battlecruiser` scheme.
- Do not run the test action on your own. When a change needs verifying, say that it has not been built or tested and ask whether to run it.

## Things to avoid

- Do not remove the `#Preview` or `#Playground` blocks in `ContentView.swift` unless asked; they are used for quick iteration.
- Do not modify `xcuserdata/` files. They are per-user Xcode state and are ignored by git.
- Do not edit `LICENSE`.
