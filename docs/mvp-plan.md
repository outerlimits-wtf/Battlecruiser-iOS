# Battlecruiser MVP: architecture and build order

**Status: approved 2026-10-16** (see decisions D22 and D23).

Based on the decisions in [backend/05-decisions.md](backend/05-decisions.md) and the API
described in [backend/03-api-reference.md](backend/03-api-reference.md).

## What the MVP is

A read-only iPhone app showing London pubs from PubDB's production API:

- **Map** (the default screen): **shows where you are**, as in Apple Maps or Google Maps:
  the blue location dot with its heading cone, a button to re-centre on yourself, and
  the map opening centred on you. 🚢 pins in the visible area are emphasised by whether
  they are open now.
- **List**: the same pubs as the visible map area, open first, then by distance.
- **Pub detail**: tap a pin or a row to see open/closing time, tonight's last orders or
  kicked-out time, Guinness price, the week's opening hours, contact links, features,
  name history, photo and sources.
- **Honest about freshness**: refetches when it goes stale, and says "as of 22:41" when
  showing older data.

Not in the MVP: sign-in, contributions, reviews (writing), hit list, feed, leaderboard,
filters other than pubs/bars, search, iPad layout, offline download of all of London,
bundled symbol artwork.

## Architecture

### Layers

```
┌──────────────────────────── SwiftUI views (MainActor) ─────────────────────────────┐
│  RootView ── Map/List toggle                                                        │
│    ├─ PubMapView      Map + 🚢 annotations, reports camera changes                  │
│    ├─ PubListView     rows for the same results                                     │
│    └─ PubDetailSheet  summary at once, detail when loaded                           │
│  Shared components: OpenPill, ShipPin, FreshnessLabel, AttributionFooter, …          │
└───────────────────────────────┬────────────────────────────────────────────────────┘
                                │ reads state / calls intents
┌───────────────────────────────▼──── state (@Observable, MainActor) ────────────────┐
│  PubsModel      visible region → results, loading/error, fetchedAt, refresh timer  │
│  DetailModel    per-pub detail, keyed by id, loaded on demand                      │
│  LocationModel  CLLocationManager wrapper: permission + current location           │
└───────────────────────────────┬────────────────────────────────────────────────────┘
                                │ async calls
┌───────────────────────────────▼──── services (nonisolated, Sendable) ──────────────┐
│  PubDBClient    builds requests (at, lat/lon, bbox, amenity=pub), checks the        │
│                 response, decodes, maps errors                                      │
│  ResponseCache  raw JSON Data in Caches/, stored with the time it was fetched       │
└───────────────────────────────┬────────────────────────────────────────────────────┘
                                │
┌───────────────────────────────▼──── models (nonisolated, Sendable, Decodable) ─────┐
│  PubSummary, PubDetail, Symbol, Photo, WeekRow, TimelineStop, APIErrorBody, …       │
└────────────────────────────────────────────────────────────────────────────────────┘
```

Rules:

- **Views hold no networking or business logic.** They render model state and call
  model methods ("region changed", "pub selected", "refresh").
- **Models (`@Observable`) own state and orchestration**: debouncing, cancelling
  in-flight requests, deciding when data is stale.
- **Services know HTTP and files, nothing about UI.**
- **Pure functions for the small amounts of logic**, so they are easy to unit test:
  region → bbox, id → path encoding, display ordering, pin styling, "is this stale".

### The project's concurrency settings

The project is set to **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`** with **approachable
concurrency** (Xcode 26's defaults for new apps). Unannotated code runs on the main actor.
That suits views and the `@Observable` models. Two places need to opt out:

- **Model structs and their `Decodable` conformances are marked `nonisolated`**, so
  JSON can be decoded off the main thread and the values passed between actors
  (`Sendable`).
- **`PubDBClient` and `ResponseCache` are `nonisolated`.** `URLSession`'s `async` APIs
  already wait off the main thread, so the main cost to keep off the main actor is
  decoding about 0.5 MB of JSON. A `@concurrent` decode function, or a client
  that is `nonisolated` throughout, handles that.

**With modules (below), this mostly takes care of itself.** Each package module sets its
own default: the non-UI modules are nonisolated by default, so models, client and cache
need no annotations, while the UI modules default to the main actor as the app does.

**Swift language mode:** the target is in Swift 5 mode. I suggest **leaving it** for
the MVP. The main-actor default already removes most concurrency friction, and moving to
Swift 6 mode later is a one-setting change with warnings to work through. (Decision R3
below.)

### Modules (decision D24, approved)

The code is split into modules of one local Swift package, `BattlecruiserKit/`, which sits at the repository's top level next to the app project and is part of `Battlecruiser.xcworkspace`. The app
target holds only the entry point and the wiring that puts modules together.

```
Battlecruiser.xcworkspace
├── Battlecruiser.xcodeproj         app target: @main, composition root, assets, Info.plist
└── BattlecruiserKit/           one local package, several modules (library products)
    ├── Package.swift
    ├── Sources/
    │   ├── PubDBModels/        Decodable API types. Foundation only.
    │   ├── PubDBClient/        HTTP client, endpoints, errors, bbox and id encoding
    │   ├── ResponseCache/      raw-JSON disk cache with fetch times. Foundation only.
    │   ├── UserLocation/       CLLocationManager wrapper: permission and current location
    │   ├── DesignSystem/       SwiftUI building blocks: ShipPin, OpenPill, FreshnessLabel, AttributionFooter
    │   ├── PubsFeature/        PubsModel plus map and list views (shared state, so one module)
    │   └── PubDetailFeature/   DetailModel plus the detail sheet
    └── Tests/
        ├── PubDBModelsTests/   decoding tests and fixtures (moved from the app's Tests/)
        ├── PubDBClientTests/
        ├── ResponseCacheTests/
        ├── PubsFeatureTests/   ordering, pin styling, staleness (the pure functions)
        └── PubDetailFeatureTests/
```

Dependencies only point downwards:

```
App ──▶ PubsFeature ──┬──▶ PubDetailFeature ──┬──▶ DesignSystem ──▶ PubDBModels
                      ├──▶ UserLocation        │
                      ├──▶ DesignSystem        └──▶ PubDBClient ──┬──▶ PubDBModels
                      └──▶ PubDBClient                            └──▶ ResponseCache
```

(As built. The cache sits under the client rather than the features, because
only the client sees the raw response bytes the cache stores. Milestone 7c.)

Package settings:

- `swift-tools-version: 6.2`, platform `.iOS(.v18)`, Swift 5 language mode
  (`swiftLanguageModes: [.v5]`), the same as the app (decision R3).
- **UI modules** (`DesignSystem`, `UserLocation`, both features) set
  `.defaultIsolation(MainActor.self)`, like the app.
- **Non-UI modules** (`PubDBModels`, `PubDBClient`, `ResponseCache`) keep Swift's normal
  nonisolated default, so decoding and networking run off the main thread without
  annotations.
- Fixtures move into `PubDBModelsTests` as package resources (`resources: [.copy("Fixtures")]`),
  loaded with `Bundle.module`.
- Package test targets are added to the `Battlecruiser` scheme, so Cmd-U runs
  everything.

What changes compared to the single-target plan:

- Types that other modules use become `public`, with `public` initialisers where
  other modules or previews build them. Swift's automatic memberwise initialiser is
  `internal`, so it doesn't cross a module boundary.
- The milestone 1 models and tests moved from `Sources/Models` and `Tests/` into
  `PubDBModels` and `PubDBModelsTests`. The app's `BattlecruiserTests` target stays,
  for app-level tests later.

**Approved** with one package, `BattlecruiserKit` (P1, P2). Modules are added to `Package.swift` as each one is built; `PubDBModels` came first.

### Key behaviours

**Fetching the map's pubs (`PubsModel`)**

1. The map reports `onMapCameraChange(frequency: .onEnd)` with the new region.
2. The model waits about 300 ms (debounce). If the region changed again in that time,
   it starts over. It skips the fetch if the new region sits inside the last one
   fetched, at a similar zoom.
3. It cancels any in-flight request and calls
   `GET /api/v1/pubs?bbox=W,S,E,N&amenity=pub&limit=200&at=…&lat=…&lon=…`.
4. It sorts the results for display (open → unknown → closed, then by distance),
   publishes them, records `fetchedAt` and writes the raw response to the cache.
5. On failure it keeps the previous results and marks them stale. It never blanks the
   map.

**Your location on the map (decision D21).** This is core to the app: "what's open near
*me*" needs the user on the map. All of it is first-party SwiftUI MapKit (iOS 17+):

- `UserAnnotation()` inside the `Map` draws the standard blue dot, with the accuracy
  halo and heading cone, exactly as in Apple Maps.
- `.mapControls { MapUserLocationButton(); MapCompass(); MapScaleView() }` adds the
  familiar "locate me" button, which recentres and then switches to follow-with-heading
  on a second tap.
- The camera starts at `.userLocation(fallback: .region(centralLondon))`, so it opens
  on the user once a fix arrives, and on London until then or if permission is refused.
- Panning away stops following the user, as in Apple Maps. The locate button brings it
  back.
- `LocationModel` asks for when-in-use permission at first launch, with a short
  explanation string, and passes the latest location as `lat`/`lon` to the API for
  distances. If permission is denied, the map still works on London and offers a
  route to Settings.
- Pubs are never drawn over the blue dot: the `UserAnnotation` sits above the pins.

**Pins (decision D17).** Every pub is 🚢. Styling comes only from values the server sent:

| `open.state` | Pin |
|---|---|
| `open` | large, full colour, drawn on top; a subtle highlight when `closingSoon` |
| `unknown` | medium, neutral. Neither open nor closed. |
| `closed` (or `status.serving == false`) | small, greyed out, drawn underneath |

**Detail (`DetailModel`).** Selecting a pub opens a sheet at once with the summary
already in hand, then loads `GET /pubs/{id}` and caches it in memory by id. Sheet
detents: medium (summary plus tonight) and large (everything).

**Freshness.** Refetch the visible region when:

- the app returns to the foreground,
- every 5 minutes while visible, or every minute if any visible pub has `closingSoon`.

`FreshnessLabel` shows "as of 22:41" whenever the data came from the disk cache or is
more than 5 minutes old.

**Launch.** Show the cached last region and results at once, marked with their age.
Request location. Fetch fresh results for the user's area, or for the cached or default
region (central London) if location is refused.

**Attribution (licence conditions).** "© OpenStreetMap contributors" stays visible as fine
print on the map and in the list's footer. Photo attribution and licence sit under every
photo. The detail sheet does not repeat the OSM credit (decision D25).

**Errors.** One `APIError` type: a transport failure (offline, timeout), an HTTP
error with the server's `code`/`message`, an "unexpected content" error (HTML where JSON
was expected), and a decoding error. The UI shows the server's `message` where there is
one, otherwise a short generic line, and always keeps what it already has on screen.

### Testing

- **Swift Testing**, in a unit-test target that has to be added in Xcode (it doesn't
  exist yet).
- **Fixtures captured from production**: a list response, a busy pub detail, a sparse
  pub detail, an error body. Decoding tests run against real payloads, so a shape
  mismatch shows up as a failing test, not a blank screen.
- **Pure-function tests**: region → bbox (longitude first), id encoding (`node/1` →
  `node%2F1`), display ordering, pin styling, staleness rules.
- **Client tests** with a stub `URLProtocol`: the right URL and query, HTML-with-200
  treated as an error, error bodies decoded.
- **SwiftUI previews** fed from the fixtures, so every screen can be looked at without
  the network.
- No UI-test target for the MVP.

## Build order

Each milestone ends with something you can run in the Simulator, or tests that pass, and
is a sensible point to commit.

| # | Milestone | Done when | Needs you to |
|---|---|---|---|
| 0 | **Groundwork.** Folder layout. Rename `MyApp` → `BattlecruiserApp`. Add a unit-test target. Add the location permission string. Capture production fixtures. | The app still launches. An empty test runs. | Add the test target in Xcode (File → New → Target → Unit Testing Bundle, Swift Testing), and add `NSLocationWhenInUseUsageDescription` in the target's Info tab. Or allow me to edit the project file for these two. |
| 1 | **Models + decoding.** All model types, decoding tests against fixtures. | Tests pass on the real list and detail payloads. | Run the tests (project rule: I don't build or test without asking). |
| 2 | **API client.** `PubDBClient`, endpoint building, error mapping, stubbed client tests. A throwaway debug screen listing 20 pubs from production. | Real pub names appear in the Simulator. | Run it |
|  | *Done in two steps: (a) the `PubDBClient` module and its tests; (b) linking the package into the app and the debug screen.* | | |
| 3 | **Map with you on it.** `PubMapView` with the blue location dot (`UserAnnotation`), locate-me button, compass and scale. `LocationModel` and the permission flow. The camera opens on the user, falling back to central London. 🚢 pins styled by open state, region → fetch with debounce and cancel, `lat`/`lon` sent for distances, OSM attribution. | The map opens on your location with the blue dot (in the Simulator: Features → Location, e.g. a London coordinate). Panning loads pins, and the locate button brings you back. Refusing permission still works on London. | Run it |
| 4 | *(merged into 3: location is part of the first map, not an add-on)* | | |
| 5 | **Pub detail.** Sheet with detents. Sections: header and status, open and tonight, Guinness, week table, contact (call, website, directions in Apple Maps), features, timeline, photo with attribution, sources. | Tapping any pin shows a complete, readable detail. | Review the look |
| 6 | **List and toggle.** `PubListView` with the same results and order, a Map/List toggle (map by default), tap → same sheet. | Switching views keeps the same pubs and selection. | Review |
| 7 | **Freshness and cache.** Foreground and timer refetch, `FreshnessLabel`, `ResponseCache` for the last list and recent details, a quick start from cache, offline behaviour. | Airplane mode: the app still opens, with dated data and a clear offline state. | Run it |
| 8 | **Polish.** 🚢 app icon, empty, loading and error states, a message outside London, VoiceOver labels (from the server's labels), Dynamic Type, dark mode check. | It feels finished in daily use. | Review on a real phone if you like (a free Apple ID is enough) |

The first useful screen (you and the pubs around you on a map) is milestone 3. Milestones 1–2 are deliberately
small and tested, because everything after them depends on the decoding being right.

## Decisions for you in this plan

| # | Question | My suggestion |
|---|---|---|
| R1 | Detail as a **sheet with detents** over the map/list (Apple Maps style), or a **pushed full screen**? | Sheet. It keeps the map visible, which suits "what's near me". |
| R2 | Map/List switch: **segmented control in a toolbar**, or a **floating button** on the map? | Segmented control at the top. Plain and obvious. |
| R3 | Stay in **Swift 5 language mode** for the MVP? | Yes (see above) |
| R4 | Skip `GET /meta` in the MVP? Every label the MVP shows already arrives in the pub payloads, and the spec says to use `meta` for things the MVP doesn't have yet (editors, limits). | Skip it, and add it with contributions. |
| R5 | Pin count per fetch: `limit=200`? | 200, then adjust after seeing it on screen. |
| R6 | Can I make the two small project-file changes in milestone 0 (test target, location string) myself, or will you do them in Xcode? | Your call. The project rules prefer you do them in Xcode. |
| P1 | **One local package with several modules** (above), or **one package per module** (`PubDBModels/`, `PubDBClient/`, … as separate packages)? | One package. A single `Package.swift` where the dependency graph is visible at a glance, with the same enforced boundaries between targets. Split later if one ever needs to be shared or versioned on its own. |
| P2 | Package name? | `BattlecruiserKit` |

## Risks and unknowns

- **`#Playground` with iOS 18.** `ContentView.swift` uses the `Playgrounds` module.
  I haven't confirmed that it builds with the minimum lowered to iOS 18. It needs a build
  to check. If it fails, the fix is an `if #available` or a compile-time condition, not
  removing it.
- **Production is a Raspberry Pi** and the API has no `ETag` or paging yet (doc 3). Fine
  at our scale. Watch response times when zoomed out.
- **The spec and production differ** (doc 3). We code to production. If the backend
  author "fixes" the code to match the spec (e.g. `bbox` order), the app breaks.
  Worth a message to them before testers rely on it.
- **SwiftUI `Map` has no pin clustering.** If zoomed-out London is a mess of boats, the
  fallback is `MKMapView` wrapped for SwiftUI, still first-party but more code. Decide
  after milestone 3.
