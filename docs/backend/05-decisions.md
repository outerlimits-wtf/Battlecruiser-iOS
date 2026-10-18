# 5. Decisions and open questions

## Decided

### 2026-10-16, first round

| # | Decision | Notes |
|---|---|---|
| D1 | **First release is TestFlight only**, for the creators and invited testers. The App Store is a later goal, so choices should not rule it out. | |
| D2 | **Build the MVP on the backend as it is.** No backend changes are needed or expected while its author is away. | Possible because production's v1 API is public for reads (doc 4). The original worry, Cloudflare Access blocking the app, no longer applies: Access was removed on 2026-08-26. |
| D3 | **Target the v1 API** (`/api/v1`), the version production runs. | See D13. |
| D4 | **MVP scope: pubs on a native MapKit map, tappable for information.** Read-only. | Filters beyond pubs/bars wait. See D18 for the list view. |
| D5 | **No contributions, reviews, sign-in or hit list in the MVP.** | See D19 for what comes after. |
| D6 | **iPhone first**, iPad later. | See D16. |
| D7 | **No food-hygiene data.** | The roadmap plans to remove it. |
| D8 | **First-party frameworks only**: SwiftUI, MapKit, Foundation, CoreLocation. | Matches the project's rule against adding packages. |
| D9 | **No SwiftData for the MVP.** An in-memory store plus a raw-JSON file cache in `Caches/`, and `UserDefaults` for small preferences. | Reasoning in doc 4 §5. |
| D10 | **Minimum iOS 18.0** (lowered from 27.0). | Everything planned (SwiftUI `Map`, `onMapCameraChange`, `@Observable`) exists from iOS 17. Anything newer goes behind `if #available`. |
| D11 | **The iOS side does not write backend code.** Backend changes are asks for the backend author (doc 4 §8). | |
| D12 | **The app computes nothing the server already provides**: no opening-hours parsing, no formatting of prices, times or distances. It sorts and styles on values the server sent, and refetches when they go stale. | The rule from the v1 spec. |

### 2026-10-16, second round

| # | Decision | Notes |
|---|---|---|
| D13 | **The backend's source of truth is branch `chore/latest-close-and-prettier`**, not `main`, until that changes. | Where its spec and its code disagree, the code wins, because the code is what production runs (doc 3, "Spec vs production"). |
| D14 | **Development builds call production directly.** | Public reads, 300 a minute per client. Debounced map fetches stay far below that. |
| D15 | **Simulator-first; no Apple Developer account yet.** | See "Apple developer accounts" below. A paid account becomes necessary for TestFlight (D1). |
| D16 | **iPhone only for now**: `TARGETED_DEVICE_FAMILY = 1`. | Changed in the project on 2026-10-16. Put it back to `1,2` when iPad work starts. |
| D17 | **Emoji only, no bundled artwork. The app icon is a big boat 🚢, and so is every pub pin on the map.** | Pins use 🚢 in place of the server's `amenity.symbol`. Open, closed and unknown are still shown through size, colour and emphasis. Features, tonight and status use the server's `symbol.emoji` as the spec intends. Bars are hidden by default, so the lost 🍺/🍸 distinction rarely matters. If bars are shown, a colour or badge will have to tell them apart. |
| D18 | **The MVP has a map and a list, and opens on the map.** | The list shows the same results as the visible map region, in the same order: open, then unknown, then closed, each by distance. Search can come with the list or later. |
| D19 | **Authentication is phased.** MVP: none (read-only). Next, when contributions arrive: the quickest thing that works, the `WKWebView` + `pubdb_session` cookie route (doc 4 §7), accepting its limits. Long term: real user accounts with OAuth sign-in and persistent sessions, which needs backend work. | Keep auth behind one small `AuthSession` type in the app, so changing route later touches one place. |
| D20 | **Battlecruiser is the long-term name for the whole project.** "PubDB" is the backend and the data. | The bundle identifier is still Xcode's placeholder (`devplaceholder…`). Set it to something under a domain you control before the first TestFlight upload; a bundle identifier cannot change once an app record exists. |

### 2026-10-16, third round

| # | Decision | Notes |
|---|---|---|
| D21 | **The map always shows the user's own location**, as Apple Maps and Google Maps do: blue dot with heading, a locate-me button, and the map opening on the user. This is core to the MVP, not polish. | First-party `UserAnnotation` and `MapUserLocationButton`. Falls back to central London without permission. Details in [mvp-plan.md](../mvp-plan.md). |

### 2026-10-16, MVP plan approved

| # | Decision | Notes |
|---|---|---|
| D22 | **The MVP plan ([mvp-plan.md](../mvp-plan.md)) is approved with the suggested answers to R1–R6**: detail as a sheet with detents; Map/List as a segmented control at the top; stay in Swift 5 language mode; skip `/meta` in the MVP; `limit=200` per fetch; Claude may edit the Xcode project file. | |
| D23 | **Way of working: Claude never runs git commands of any kind.** The user does all git work (branches, commits). Claude does one piece of work at a time, then stops with a summary and a suggested commit message. The user reviews, builds, tests and commits before approving the next piece. | Matches the rules in `.claude/CLAUDE.md`. |

### 2026-10-16, modularisation

| # | Decision | Notes |
|---|---|---|
| D24 | **Modular from the outset.** Code lives in local Swift packages inside `Battlecruiser.xcworkspace`, and the app target stays light: entry point, composition, assets. Each module has one job and explicit dependencies. | This is why the project has a workspace. Local packages are our own code, so D8 (first-party only) still holds. Layout approved: one local package, `BattlecruiserKit`, with the modules listed in [mvp-plan.md](../mvp-plan.md), "Modules" (P1, P2). The milestone 1 models now live in its `PubDBModels` module. |

### 2026-10-18, attribution

| # | Decision | Notes |
|---|---|---|
| D25 | **The OpenStreetMap credit is fine print, not a notice.** "© OpenStreetMap contributors" sits in the map's bottom-right corner (opposite Apple's "Legal") and in the list's footer. The detail sheet no longer repeats it: the sheet sits over the map, whose credit covers the screen. | ODbL requires crediting OSM where its data is shown; this meets it without overstating it. **Photo credits stay under each photo**: Commons photos are CC BY / BY-SA, which require crediting each photographer, and a general credit cannot do that. The API's per-pub `sources` are still decoded but not shown. |

### 2026-10-18, reviews

| # | Decision | Notes |
|---|---|---|
| D26 | **The detail sheet shows drinkers' reviews, read-only.** Score out of 10, byline, date and text, newest first; the first three, then "Show all". Hidden when a pub has none. | Narrows D5: reading reviews is in the MVP, writing them is not. Reviews are public in `GET /pubs/{id}`, so this needs no sign-in. Writing ("commenting") is `POST /pubs/{id}/reviews` and needs a signed-in session, so it waits for the first phase of D19 (Q5). Reviews decode lossily: a bad one is skipped, not the whole pub. |

## Apple developer accounts, briefly

- **Simulator:** no account needed. Build and run from Xcode freely.
- **Your own iPhone:** a free Apple ID added in Xcode ("Personal Team") is enough. Apps
  installed this way stop launching after 7 days until you reinstall, and some
  capabilities are unavailable, but MapKit and location work.
- **TestFlight and the App Store:** need the paid Apple Developer Program (£79/US$99
  a year). Signing up can take a few days to verify, so start it a little before you
  want testers.

## Database snapshots, briefly

All of the backend's data lives in one file, `pubdb.sqlite`, on the Raspberry Pi. A
**snapshot** is a copy of that file taken at a moment in time. The backend's backup
script makes one every day into its author's cloud storage. With one, you can run the
whole backend on your Mac with real data and no internet. That is handy for trying
contributions later without touching the live data.

We can't make one from here. It needs access to the Pi or to the backups, and only the
backend author has those. The alternative is to build a fresh database with the
backend's scrape script, which has public data only (no drinkers' prices or reviews)
and calls several outside services. **Neither is needed for the MVP**, because it reads
from production (D14). It can wait until the backend author is back or contributions
come up.

## Still open

| # | Question | Who | Blocks the MVP? |
|---|---|---|---|
| Q1 | Will the spec or the code change where they disagree? | Backend author, when back | No |
| Q2 | Is it fine for TestFlight builds, and so testers, to use production? Development use is decided (D14). | Backend author | No. It matters only at the first TestFlight build. |
| Q3 | A database snapshot for local development | Backend author, when back | No |
| Q4 | The bundle identifier and domain for Battlecruiser (D20) | You | No. Needed before TestFlight. |
| Q5 | When do contributions come in, and with them the first phase of D19? | You | No |
