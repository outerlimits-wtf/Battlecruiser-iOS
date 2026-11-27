# Battlecruiser: parity with the web client

**Status: approved 2026-11-26**, with the decisions recorded in
[Decisions](#decisions) (P1–P8), and as D27–D34 in
[backend/05-decisions.md](backend/05-decisions.md).

**Progress (2026-11-26):** Phases A–D and F are built, including notifications
(F7, once the server shipped them) and what origin/main's web gained on
2026-11-25/26 (quote card, review likes, Guinness icon, search closing the pub).
Levels (S16) are drawn once the server sends them. E is built except the parts
waiting on server asks (the Fix panel's other editors, night forms, hours
editor, history editing: S2–S6). G1 (block) waits on S10, G2 (deep links) on
S11. Sign-in is configured and checked against WorkOS (client id, redirect and
PKCE accepted) but not yet completed with a real account. Pushes need the Push
Notifications capability added in Xcode. Two departures from the layout above:
one `Social` module holds Latest, Leaderboard, Boards and Notifications, and the
Fix-mode editors live in `PubDetailFeature/Writes` until the `Contribute` module
has more than two of them.

**Server asks (2026-11-27):** S1–S10 and S12–S16 are **deployed** to production,
along with six reworked levels. See "Where they stand" in
[server-asks.md](server-asks.md). The work they unblock is in
[Phase H](#phase-h-picking-up-the-server-asks). Still open: S11, S17, S18.

This plan follows on from [mvp-plan.md](mvp-plan.md), which is built. It covers bringing
the iPhone app level with the PubDB web client (`../pubdb/src`) in features and look, on
the v1 API (`../pubdb/spec/pubdb-api-v1.md`, checked 2026-11-08).

It is based on three read-only surveys done on 2026-11-26: the web client's UI screen by
screen, the API contract against `routes.ts`, and the current state of this repo.

## The rules this plan follows

1. **The server does everything it possibly can.** The app draws labels, it doesn't
   build them.
   - No date maths, opening-hours parsing, sorting, counting, currency formatting or
     string composition, unless it is pure layout.
   - Where the web client still computes something, the plan does **not** copy it. It
     asks the server for the field instead ([Server asks](#server-asks)), and the
     milestone waits for that field.
   - A temporary client workaround is allowed only where waiting would block everything
     else. Each one is named and listed for deletion (`PubOrdering` is the only one today).
2. **`/meta` drives anything that is a list.** That covers amenities, venue kinds,
   features, weekdays, editors (`contributableFields[].kind`), boards, photo kinds,
   report reasons, limits and `minVersion`. Adding a field, board or feature on the
   server needs no app release.
3. **Copy the web UI.** The web's layout, wording, colours and states are the reference,
   translated into native SwiftUI: a native sheet with detents, `PhotosPicker`, Apple
   Maps for directions. The visible text comes from the web client, word for word.
4. **Small files, one job each.**
   - One type per file, and no file over about 150 lines.
   - A view that has sections gets a folder of section views (as
     `PubDetailFeature/Sections/` does now).
   - Pure logic lives in its own file with its own tests.
5. **Modules stay one-way (D24).**
   - Features never import each other. They take closures such as `onSelectPub`
     and `onOpenProfile`, and a root module wires them together.
   - Lower modules (models, client, cache, auth) never import UI.
6. **Process is unchanged.** One milestone sub-step at a time, then stop for review.
   No git, no builds, no tests run by Claude (CLAUDE.md).

## Where the app is now (short)

- **Modules:** 7 (`PubDBModels`, `PubDBClient`, `ResponseCache`, `UserLocation`,
  `DesignSystem`, `PubsFeature`, `PubDetailFeature`). About 3,000 lines in all.
  Well tested against production fixtures.
- **Endpoints used:** `GET /pubs` (bbox, `limit=200`) and `GET /pubs/{id}`. `similar` is
  modelled but not shown.
- **Not covered yet:** `/pins`, `/meta`, `/me` and every write. The client is GET-only,
  with no auth, no `Retry-After` handling and a hard-coded base URL.
- **Map:** a SwiftUI `Map` with one `Annotation` per pub, driven by `/pubs`. The spec
  says not to do this (see "Building a map").

**What needs fixing before 15 more features land on it:**

| Problem | Where |
|---|---|
| `PubsMapScreen.swift` does too many jobs (288 lines): it creates all three models, owns the lifecycle and timer, and draws the banners and attribution | `PubsFeature/` |
| One feature imports another | `PubsFeature` → `PubDetailFeature` |
| No app-wide container for the client, session, meta or location | app target |
| Load/cancel/error plumbing copied in two places | `PubsModel` and `PubDetailModel` |
| An LRU cache living inside a view model | `PubDetailModel` |
| Several files hold many types (`PubDetail.swift` holds 10) | `PubDBModels/` and others |
| `PhotoView`, `SectionTitle` and `PubRow` are private, though other features will need them | `PubDetailFeature`, `PubsFeature` |
| Strings composed on the device: "x/10 (n)", "n reports", the address line, "1988–1997", "N open of M here" | various views |

Phase A deals with all of these before any new feature is built.

## Target architecture

### Modules

New modules are marked ★. Existing ones that change a lot are marked ✎.

```
BattlecruiserKit/Sources/
  PubDBModels/ ✎     Decodable API types, one per file, in folders by area:
                       Pub/ Meta/ Pins/ Account/ Community/ Writes/ Errors/
  PubDBClient/ ✎     APIRequest (method, path, query, body), one endpoint file per area,
                       PubQuery (filters → query), ETag store, 401 refresh-and-retry-once,
                       Retry-After, base URL from Info.plist. TokenProvider protocol.
  ResponseCache/     unchanged (raw JSON on disk)
  Auth/ ★            WorkOS AuthKit PKCE in ASWebAuthenticationSession, token exchange
                       and refresh, Keychain. Implements PubDBClient.TokenProvider.
  UserLocation/      unchanged; becomes injectable
  AppEnvironment/ ★  MetaStore (launch fetch + disk copy + minVersion), SessionModel (/me,
                       sign-in state, signed-in user), ThemePreference. Shared @Observable
                       state that features read from the SwiftUI environment.
  DesignSystem/ ✎    Theme tokens (the web's colours light/dark, type, radii, shadows),
                       SymbolGlyph, PubPhoto, PubCard, Pill, Chip, ChipRow, SectionHeader,
                       StateView (loading/empty/error), Toast, RankBadge, Avatar,
                       CoverageCard, InfoTip, TeardropPin
  PubsMap/ ★         MKMapView wrapper: dot overlay + renderer, full pins zoomed in,
                       PinsModel (ETag, 60 s tick, per-filter key)
  Explore/ ★         (was PubsFeature) the home screen: top bar, search, sheet with
                       list, ResultsModel (/pubs), FiltersModel + pill row + panels
  PubDetailFeature/ ✎ the panel: gallery, header, actions, tabs (Overview, Reviews,
                       About), each section its own file
  Contribute/ ★      Fix mode and editors keyed by meta `kind` (tri, text, url, phone,
                       price, hours, night, amenity, previous_name, status), NightForm,
                       HoursEditor, ReviewForm, PhotoUpload, ReportSheet, ContributionService
  Account/ ★         sign-in card, signed-in card, handle editor, avatar, sign out,
                       delete account
  Lists/ ★           Hit list and Been here (watchlist / visited + coverage)
  Feed/ ★            Latest updates (Everyone / Following)
  Leaderboard/ ★
  Boards/ ★          one screen for every board in meta
  Profile/ ★         a user's page, follow / unfollow
  Social/ ★          the Social tab: Latest (Everyone / Following), Leaderboard,
                       Boards, notifications later (S15)
  Me/ ★              the Me tab: account block, own profile, Appearance, About
  Root/ ★            RootView: the bottom tab bar (Map, Social, Lists, Me), the panel,
                       the minVersion gate; owns navigation (selected pub, open profile)
```

- `Root` is the only module that imports features. The app target creates the live
  dependencies (`PubDBClient.live`, `AuthSession.live`, `LocationModel`), hands them to
  `RootView`, and does nothing else.
- Dependencies point downwards:

```
App ─▶ Root ─▶ { Explore, PubDetailFeature, Social, Lists, Me, Profile }
Social ─▶ { Feed, Leaderboard, Boards }     Me ─▶ Account
                      │ each ─▶ Contribute (only PubDetailFeature) ─▶ AppEnvironment, DesignSystem
Explore ─▶ PubsMap ─▶ DesignSystem
AppEnvironment ─▶ PubDBClient ─▶ { PubDBModels, ResponseCache }
Auth ─▶ PubDBClient (for the TokenProvider protocol only)
UserLocation (no deps)
```

### Patterns every feature uses

- **One `@Observable` model per screen.** It owns its loading state, through a shared
  `Loadable<Value>` (idle, loading, loaded, failed, plus the previous value kept on
  failure) in `AppEnvironment`. That replaces the copied load/cancel/error code.
- **One source protocol per feature** (as `PubSource` today), which `PubDBClient`
  conforms to. Tests use fakes, previews use fixtures.
- **Writes go through `ContributionService` or a feature's own source.** After a write
  that succeeds, the model reloads what the server now says rather than patching it
  locally. The exception is the Save, Been here and Follow toggles, which update at once
  and roll back if the call fails, as the web does.
- **Errors:** switch on `code`, show the server's `message`, and keep what is already on
  screen.
- **Freshness:**
  - Send `at` on every time-dependent call.
  - Refetch every 60 s while a screen is visible, and on returning to the foreground.
  - Show "as of HH:MM" for anything from the disk cache or over 5 minutes old.
  - This applies to the open pub too, which is not refreshed today.

## Milestones

Each row is one piece of work: done, then stop for review and a commit. "Needs S*n*"
means the milestone waits on that [server ask](#server-asks).

### Phase A: foundations (no visible change)

| # | Work | Done when |
|---|---|---|
| A1 | Split the multi-type files (`PubDetail`, `PubSummary`, `PubDBClient`, `LocationModel`, `PubDetailSheet`, `DetailHeader`) into one type per file, in area folders. No behaviour change. | Tests still pass. |
| A2 | Make the client general. `APIRequest` gets a method, a JSON or multipart body, and headers. Endpoint factories move into one file per area. Shared `JSONDecoder`. Base URL from Info.plist. `Retry-After` is read into `PubDBError.rateLimited`. | Client tests cover POST/PUT/DELETE, the body, 429 and the base URL. |
| A3 | Conditional GET: an ETag store keyed by request, `If-None-Match` sent, and a 304 returned as "unchanged". | Tests: 200 then 304 returns the same value with no decode. |
| A4 | `/meta`: models, endpoint, `MetaStore` (fetched at launch, disk copy used at once, refreshed on foreground). `MinVersionGate` compares the version part by part, as numbers. | Decoding test on a captured `/meta` fixture. The gate's comparison is tested ("0.10" > "0.9"). |
| A5 | `AppEnvironment` module with `Loadable`, `MetaStore` and a `SessionModel` stub (signed out until Phase D). `PubsModel` and `PubDetailModel` move onto `Loadable`. | Tests unchanged in what they check. |
| A6 | Design tokens: the web's colour table as `Color` light/dark pairs, the type scale, radii and shadows. `ThemePreference` (System, Light or Dark, stored in `UserDefaults`; add `CA92.1` to `PrivacyInfo.xcprivacy` in the same change). | A preview sheet shows every token in both modes. |
| A7 | Shared components in DesignSystem: `SymbolGlyph` (the spec's bundled → url → emoji rule), `PubPhoto` (url → thumbUrl → placeholder, credit underneath), `SectionHeader` (small caps), `Pill`, `Chip`, `StateView`, `Toast`, `RankBadge`, `Avatar`, `InfoTip`. | Previews for each. |
| A8 | The `Root` module. `PubsMapScreen` is split: lifecycle and timers move into models, and banners become their own views. `PubsFeature` stops importing `PubDetailFeature`, and `Root` wires selection between them. The app target shrinks to `RootView(environment: .live)`. | The app behaves exactly as today. |

### Phase B: the map and the list, as on the web

| # | Work | Done when |
|---|---|---|
| B1 | `/pins`: decode the GeoJSON features (off the main actor). `PinsModel` refetches when the filters change and every 60 s with `If-None-Match`; a 304 changes nothing on screen. | Tests for the ETag path, and a fixture decode of about 5,700 features. |
| B2 | The `PubsMap` module: an `MKMapView` behind `UIViewRepresentable`, with the base map behind a small `MapBase` choice (Apple Maps now; vector CARTO later is a swap, not a rewrite, per P2), with the user location, locate button, compass and scale, camera reporting (300 ms after it stops), and the OSM credit. Replaces the SwiftUI `Map`. | Same map behaviour as today, with no pins yet. |
| B3 | The dot overlay: one `MKOverlay` and a custom renderer that paints every pub, quietest first. Radius, opacity, outline and colour per `pin` state come from the spec's table. It redraws on every frame of a gesture. | All of London pans and zooms smoothly on a device. |
| B4 | Full pins once zoomed in: the web's teardrop, coloured by `pin` state, with the pint logo as its glyph for every pub (Decision P1; one asset, so swapping it is one line), only for pubs in view plus 25%, capped at 300. Diffed by `id`, views reused, the selected pub always a full pin, dots skipped under full pins. Closing-soon pulse animates transform and opacity only, and is off with Reduce Motion. | Zooming past the threshold swaps dots for pins without flicker. Selecting a pin opens the pub. |
| B5 | The Map tab, copying the web's mobile layout: a search pill ("Search pubs, streets, breweries", debounced 250 ms, ✕ to clear), a native sheet with a peek, half and full detent holding the list or the panel, and the map behind it. The Map/List segmented control goes (Decision P5). The bottom tab bar (Map, Social, Lists, Me; P6) lands here with the other three tabs as placeholders. | The layout matches the web on a phone. |
| B6 | Results list: `PubCard` rows (photo, name, the summary line, hours pill or status, tonight, distance, listed and features). Header "N pubs · ● k open" and its subtitle. Skeletons, error with "Try again", empty state "Nothing doing" with its buttons, and the "Showing the closest N" footer. **Needs S1** (ordering and counts) and S7 (labels). | List matches the web for the same area. `PubOrdering` and `openCount` are deleted. |
| B7 | Search (`q`) and "🌍 Everywhere": both drop the bbox; Everywhere shows a chip to turn it off. | Typing a name finds pubs anywhere. |
| B8 | Filters: `PubQuery` in the client, `FiltersModel` in Explore, and the pill row (Open now, Kind, Hours, Features, Rating, Guinness, Has photo, Listed, Closed pubs, Latest close, Reset). Each pill's panel is its own file. Options come from meta (**needs S8** for the rating and price choices). Pins and the list share the filters. | Each filter changes pins and the list together. |

### Phase C: the pub panel, read-only, as on the web

| # | Work | Done when |
|---|---|---|
| C1 | Panel shell: gallery strip (snap carousel, credit on a scrim), close button, brand, name, summary line with the venue kind's ⓘ note, hours pill and address. Actions row with Directions (a Get there sheet: Apple Maps, Citymapper, Google Maps). Sticky tabs: Overview, Reviews (n), About. | Opening any pub shows the web's header. |
| C2 | Overview, part 1: Tonight (last orders, kicked out, garden), "What's there" (yes features, night days) and the Guinness card. | Matches the web for a busy pub and a sparse one (fixtures). |
| C3 | Overview, part 2: price graph (**needs S7**, band and summary from the server; the app only plots), the week table (door says, bell and out; tonight highlighted) and its footnote, Contact pills, and Nearby (`/similar`) cards. | As above. |
| C4 | Reviews tab, read-only: the first 3, then "Show n more", with the avatar, a handle you can tap, rating label and date. The empty text "Not a word from anybody…". | As above. |
| C5 | About tab: History timeline, "Everything else we know" (**needs S7**, labelled `osmTags`), and the footer with sources, verified date and contributor count. Shows `sources`, superseding part of D25 (Decision P4): public credits only (PubDB, OSM, Commons and so on), never internal scrapers such as Hopscout. **Needs S15** so the server sends only the public ones. | As above. |

### Phase D: signing in

| # | Work | Done when |
|---|---|---|
| D1 | The `Auth` module: AuthKit PKCE in `ASWebAuthenticationSession`, code exchange and refresh with WorkOS directly, and tokens in the Keychain. Behind an `AuthSession` protocol (D19). **Needs you to** register the redirect `wtf.outerlimits.battlecruiser:/auth/callback` in WorkOS and give the client id. | Tests against a fake token endpoint. |
| D2 | Client auth: a bearer header on every request (reads too, for `canRemove`), and on a 401 one refresh, then one retry. `SessionModel` calls `/me` at launch and on resume, and treats `why: "invalid-bearer"` as a refresh trigger. | Tests for refresh-and-retry-once and for sign-out on a second failure. |
| D3 | Account UI, in the Me tab's account block: the "🔑 Sign in" card, the signed-in card with its stats, the handle editor (PATCH `/me`), sign out, and **delete account** (DELETE `/me`, which the App Store requires). Update `PrivacyInfo.xcprivacy` for the account data. | Sign in, rename, sign out and delete all work against production. |
| D4 | Avatar: add or change it with `PhotosPicker` (POST `/me/avatar`), and remove it (DELETE). | As on the web, plus removal, which the web lacks. |

### Phase E: contributing

| # | Work | Done when |
|---|---|---|
| E1 | `ContributionService` and the shared Fix-mode plumbing: post, handle 201, 202 (`message`) and 409, show the toast ("Saved. The next person through the door gets that."), reload the pub and refresh the pins and list. **S12** would save the reload. | Tested with a fake source. |
| E2 | Save and Been here toggles in the actions row (optimistic, rolled back on error); signed out, they become sign-in links. | As on the web. |
| E3 | Reviews: the rating control from meta (`minRating`–`maxRating`), the body (`maxReviewBody`), Post, ✕ on your own reviews in Fix mode, and Report on other people's. | As on the web. |
| E4 | Editors by `kind`, one file each: `tri`, `text`, `url`, `phone`, `price` (meta's min and max), `amenity` (venue kinds), `status`. Fix mode has the Name, Type, Still there? and Owner pickers, plus About "Details" and "Added by drinkers" with ✕. **Needs S4** (current values, placeholders, order) and **S5** (structured status). | Every field the web can edit, iOS can edit. |
| E5 | Tonight forms: last orders, kicked out and garden. **Needs S3** (the server says which night it is). | No session-day maths on the device. |
| E6 | Hours editor (presets, day toggles, opens/closes, "Don't know"). **Needs S2**: structured hours in and out, so the app never parses `doorSays` or writes OSM syntax. | Saving hours on iOS gives the same `hours.raw` as the web. |
| E7 | History: add, edit and remove previous names. **Needs S5 and S6** (structured values; timeline entries carry `contributionId`). | No matching stops to contributions by string on the device. |
| E8 | Photos: `PhotosPicker` or the camera, re-encoded to JPEG at `clientMaxSide` (never HEIC), kind chips from meta, caption up to `maxCaption`, the licence line from `photoLicense`, and the server's `message` shown. Delete your own photos, and report other people's. | Upload works and the gallery refreshes. |
| E9 | `ReportSheet`: reasons from meta, filtered by `types`, with an optional note. Used on photos and reviews. | "Reported, thanks". |

### Phase F: the other tabs

The web's side menu becomes a bottom tab bar (Decision P6): **Map**, **Social**,
**Lists** and **Me**. Each tab has its own `NavigationStack`. The pub panel opens over
whichever tab you are on.

| # | Work | Done when |
|---|---|---|
| F1 | Me tab: the account block (from D3), Appearance (System, Light, Dark) and the static About page (copy from the web, including the data credits). | |
| F2 | Social tab shell, with Latest updates (`/feed`): Everyone, and Following when signed in. | |
| F3 | Leaderboard in Social, with your own row highlighted (**S7** for the footer sentences). | |
| F4 | Boards in Social: one screen for every board in `meta.boards`, drawing entries in the order the server sends them, with the note, excluded and empty states. | A board added on the server appears without a release. |
| F5 | Lists tab: Hit list and Been here, both lists of `PubCard`. Been here starts with a `CoverageCard`. | |
| F6 | Profile: header, follow / unfollow, stat tiles, coverage, and the Reviews and Been here tabs. Opened from handles in reviews, the feed and the leaderboard, and as "My profile" in Me. | |
| F7 | Notifications in Social, **needs S15b** (there is no notifications endpoint yet). | |

What else earns a tab is still open. Today Lists and Me fill the last two slots.

### Phase G: finishing

| # | Work |
|---|---|
| G1 | Block a user, **needs S10**. It is required before the App Store (Guideline 1.2). |
| G2 | Deep links: `/pub/<id>` opens the pub. **Needs S11** (the `apple-app-site-association` file) for universal links. A custom-scheme link can work before that. |
| G3 | Offline and freshness pass across every screen: the disk copy shown at once, "as of", and offline notices. |
| G4 | Accessibility pass: VoiceOver labels, Dynamic Type stacking and Reduce Motion on every new screen, plus `Spoken` rewording where the server's text reads badly aloud. |
| G5 | Update CLAUDE.md's layout section, `Package.swift` comments, and `docs/backend/05-decisions.md` with what was decided here. |

### Phase H: picking up the server asks

Unblocked: the server work was deployed on 2026-11-27. Keep every new field optional
in the models, so old cached responses still decode. The table is by number; the
order they're built in is in [the handoff log](#phase-h-order-roadmap-and-progress-handoff-log) below it.

| # | Work | Needs | Done when |
|---|---|---|---|
| H0 | Fresh production fixtures for `/pubs`, `/pubs/{id}`, `/meta`, `/me`, `/users/{u}`, `/leaderboard`, `/usernames/random` and `/me/blocks` (docs/test-fixtures.md), and decoding tests for the new fields, all optional. | deploy | Old and new fixtures both decode. |
| H1 | Block a user (G1): Block/Unblock on profiles, the `isBlocked` state, and a "Blocked" list in Me from `/me/blocks`. | S10 | Required before App Store submission. |
| H2 | The list from the server (finishes B6): draw `headerLabel`, `scopeLabel`, `counts`, `truncated`; delete `PubOrdering` and `openCount`. | S1 | The last named workaround is gone. |
| H3 | Labels everywhere (S7): `ratingLabel`, `addressLine`, `contributorLabel`, `checkedAtLabel`, `spanLabel`, `osmFacts`, `hours.sourceLabel`, `percentLabel`, `joinedAtLabel`, `createdAtLabel`, `summaryLines`. Delete each string the device composes today. Several PRs, one area each. | S7 | No date or number formatting left in views. |
| H4 | Price graph (C3) from `priceHistory.band`, `window`, `ticks`, `summaryLabel`, `change`. | S7 | The app only plots. |
| H5 | Filters from meta (B8): rating and Guinness steps from `meta.filters`, the Guinness range from `limits.guinnessFilter`, and a note when `ignored` is non-empty. Check that `amenity` is always sent unless `kinds` is set. | S8 | No hard-coded chip lists. |
| H6 | Conditional GETs for `/pubs/{id}` and `/meta` (A3's store). The detail's tag is per account, so key it by account too and clear it on sign-out. | S9 | 304 on reopen; no account sees another's tags. |
| H7 | Writes use what comes back (E1): show `entry`, swap in `pub`, skip the reload; send `at`, `lat`, `lon`. | S12 | One request per write. |
| H8 | Fix-panel editors (E4) from `editable`, `section`, `order`, `placeholder`, `maxLength`; the `status` and `weekday` kinds; `parts` for structured values. An unknown kind gets a text editor. | S4, S5 | Every field the web can edit, iOS can edit. |
| H9 | Night forms (E5) using `session`, and posting `{ at }`. | S3 | No 06:00 maths on the device. |
| H10 | Hours editor (E6) from `weekTable[].state` and `sessions`, and posting `{ days }`. Show the `400` on `field: "value"`. | S2 | Same `hours.raw` as the web. |
| H11 | History editing (E7): edit and remove through `contributionId`/`canRemove`, and hide OSM stops with `hideValue`. | S5, S6 | No string matching. |
| H12 | Limits from meta (S13): the report note, avatar size, handle rules and page sizes; `Retry-After` on the photo 429. Plus the 🎲 random handle (S14) in the handle editor. | S13, S14 | No hard-coded limits. |
| H13 | Sources (C5): draw `sources[]` with each `license`. | S15 | Credits as the server sends them. |

#### Phase H: order, roadmap and progress (handoff log)

Decided with the user on 2026-11-27. **Any agent picking this up: read this section
first, then do the next unticked step** (CLAUDE.md Workflow). Each step is one commit
holding the code, its ticked box and a dated log line. Nothing is built or tested by
the agent; the user checks in Xcode, so each log line says what to check. If the last
log line says a step was started but not committed, check `git status` first.

**Roadmapped, not now:**
- **H1 (block a user) is an App Store blocker**, parked with the others: see
  [App Store blockers](#app-store-blockers). The app isn't going to the App Store yet,
  so it waits until those are tackled together.
- **H13 (sources) is low priority.** After everything below.

**Working order** (pub editing first, as asked):

1. [x] **X1 · Sheet bug.** Searching with the sheet at peek raises the sheet to full,
   but its content stays hidden as if still at peek. The results must show at the new
   detent. (`DesignSystem/Sheet`, `PubsFeature/Search`.)
2. [x] **H0** · fixtures and decoding tests for the new fields (all optional).
3. [x] **H7** · writes use what comes back. The plumbing every editor below sits on.
4. [ ] **H8** · Fix-panel editors from `editable` and meta (`section`, `order`,
   `placeholder`, `maxLength`, `status`, `weekday`, `parts`). Likely two or three steps:
   (a) models and the panel's layout by `section`/`order`; (b) the simple kinds;
   (c) `status`, `weekday` and `parts`.
5. [ ] **H10** · hours editor. See "Time pickers" below.
6. [ ] **H9** · night forms (last orders, kicked out, garden). **Not the web's form**,
   which the user finds a poor experience: build them as the hours editor's
   sibling, the same day rows and the same picker, but with a closing time only (no
   open time). The night comes from `session`; post `{ at }`.
7. [ ] **H11** · history editing.
8. [ ] **H2** · the list from the server.
9. [ ] **H3** · labels from the server, one area per step.
10. [ ] **H4** · price graph.
11. [ ] **H5** · filters from meta.
12. [ ] **H6** · conditional GETs.
13. [ ] **H12** · limits from meta, and the 🎲 handle.
14. [ ] **H13** · sources (low priority).

**Time pickers (H9, H10):** closing times are picked in **5-minute steps**. Every
time picker in the hours editor and the night forms uses the same shared control, so
the step lives in one place.

**Log** (newest last; one line per step: date, step, what changed, what wasn't verified):

- 2026-11-27 · plan · This section added; Leaderboard row layout fixed beforehand
  (`Social/LeaderboardRow.swift`).
- 2026-11-27 · X1 · Cause: the keyboard's height went into the sheet's bottom inset, so
  at peek the sheet grew to the keyboard while its content stayed hidden (detent still
  `.peek`). `BottomSheet` now ignores the keyboard and scrolling dismisses it; typing a
  search raises the sheet to `.full`. Not built. Check: search from peek, half and an
  open pub; results show above the keyboard; scrolling hides the keyboard.
- 2026-11-27 · H0 · Fresh `-1127` fixtures beside the old ones (docs/test-fixtures.md) and
  `ServerAsksFixtureTests`, which decodes them with today's models. New fields are
  modelled by the step that uses them, not here. `/me` and `/me/blocks` not captured
  (need sign-in). Not run. Check: PubDBModelsTests pass.
- 2026-11-27 · H7 · `WriteResult.pub` (decoded leniently); contribution and review POSTs
  send `at`/`lat`/`lon` (`PanelContext.location`, from the root); `PubDetailModel.apply`
  shows the returned pub, falling back to `refresh()` when absent (removals, 202s). The
  disk copy of the pub isn't updated by a write (next GET does it). `entry` not modelled:
  the pub already holds it. Not built or run. Check: add a fact and a review signed in;
  the panel updates with one request; WriteEndpointTests and ServerAsksFixtureTests pass.

### Phase L: levels (Walk-in, Half Pint Hero, Pub Crawler, Punter, Regular, Lock-in)

The app already decodes and draws `level`: `LevelBadge` on leaderboard rows,
`LevelProgress` on the signed-in card and profile, and "How levels work" (`LevelsPage`)
in Me. The models match the shape built in S16, but nothing has been checked against
a real response yet. The live levels are listed in server-asks.md ("Levels as live").
Owner was retired on 2026-11-27, so Lock-in is now the top. The look of each level is
yours to decide before L2.

| # | Work | Needs | Done when |
|---|---|---|---|
| L1 | Check against production: `next.key`, `emoji`, the leaderboard's short form and `xp`, `progress` at the top level (1, `next` null). Decoding tests from H0's fixtures. | deploy | Every screen with a level matches the web. |
| L2 | The look per level: badge colour or artwork for each `key` (with a fallback for a key the app doesn't know, since keys may be added or retired), and the level name and line on profiles. Colour alone never carries the level. | design | Each of the six levels is distinct in light and dark, and reads aloud. |
| L3 | Leaderboard shows `xp` beside `total` (it still ranks on `total`). | S16 | |
| L4 | A level-up moment: after a write, say what it earned and when someone reaches a new level (respecting Reduce Motion). **Needs a new server ask (S19):** write responses carry the writer's XP gained and their `level`, or the app refetches `/me`. | S19 | No XP maths on the device. |
| L5 | Badges beside names on reviews, the feed and profiles in lists. **Needs a new server ask (S20):** the short `level` on review authors and feed entries. | S20 | |

### App Store blockers

The app isn't going to the App Store yet (2026-11-27). These must all be done before
it does, and are parked until then:

- **H1 / G1: block a user** (Guideline 1.2). The server side (S10) is live.
- **S11: universal links** need a paid Apple developer account (team id, D15).
- **Push notifications** need the capability added in Xcode, under that account.
- **Sign-in checked end to end** with a real account against production.

### Loose ends

Outside the phases, so they don't get lost:

- **Check the web in a browser.** The web changes for S10, S12 and S16 are live but
  haven't been looked at, and nothing signed-in has been tried against production.
- **Server:** the `tsc` error in `src/sources/website.ts:139`; the web Profile should
  draw `joinedAtLabel`; spec stubs for S17 and S18 before they're built; Retractions
  is the only stub left.
- **S11** waits on a paid Apple developer account (team id, D15).
- **S17, S18** not yet asked for. Until S18 lands, Type chips (`kinds`) are ignored and
  the server lists pubs and bars together.
- The web bugs below (brands chips, no delete account) are still unreported.

**Not in this plan:** the admin tools (`/admin/*` is outside the API, per the spec), the
import queue, and the roadmap page. If you want admin on the phone later, it needs
`/api/v1` admin endpoints first.

## Server asks

These are needed to keep logic off the device. Under D11 they are asks for the backend;
an agent will work them on the pubdb side (P3), from the brief in [server-asks.md](server-asks.md). Milestones that need one wait for it
rather than work around it. They are listed in the order the app needs them.
S1–S10 and S12–S16 are deployed, with their final shapes in
server-asks.md; S19 and S20 are proposed in Phase L.

| # | Ask | Why | Blocks |
|---|---|---|---|
| S1 | Build the spec's "server-side list ordering and counts" stub: open → unknown → closed by distance, `sortBy=distance`, and `counts { returned, open }`. Also a `truncated` flag. | The web and iOS both re-sort and count today. | B6 |
| S2 | Structured hours: `weekTable[].sessions [{ open, close }]` plus a state, and accept a structured `opening_hours` value (or `POST /hours/format`). Validate on the server. | The web parses its own display strings back into times. | E6 |
| S3 | The night `at` belongs to: `session { day, short }` on the pub, and let night contributions take minutes or an instant. | The 06:00 cutoff rule is currently on the client. | E5 |
| S4 | Per-pub `editable { field: { value, display } }`. In `contributableFields`: `placeholder`, `maxLength`, `section` and `order`, plus a `weekday` kind for quiz and karaoke days. | Prefilling and laying out the Fix panel are hard-wired per field on the web. | E4 |
| S5 | Structured values (JSON) for `status` and `previous_name`, or `parts` in meta. | Pipe-packed strings built on the device. | E4, E7 |
| S6 | Timeline entries carry `contributionId` and `canRemove`. | The web matches stops to contributions by string. | E7 |
| S7 | Display labels the web still builds: `ratingLabel`; review and profile date labels; `joinedAtLabel`; `checkedAtLabel`; contributor count; address line; timeline span; `priceHistory` band, ticks and summary; `osmTags` as `[{ key, label, value }]` already filtered; `hours.sourceLabel`; coverage `percentLabel`; leaderboard footer lines; the list header line. | Strings composed on the device. | B6, C3, C5, F3 |
| S8 | Filter options in meta (rating steps, Guinness price steps), and `appliedFilters` echoed on `/pubs` and `/pins`. | Choice lists are hard-coded; bad filters are silently dropped. | B8 |
| S9 | ETag and 304 on `/pubs/{id}` and `/meta` (the spec's stub). | Saves data on one bar of signal. | nice to have |
| S10 | Block a user (spec stub). | App Store. | G1 |
| S11 | `apple-app-site-association` on pubdb.wtf. | Universal links. | G2 |
| S12 | Writes return the updated, presented row (or the `PubDetail`). | Saves a reload after every write. | nice to have (E1) |
| S13 | `Retry-After` on the photo 429. Add to meta the report-note maximum, avatar maximum, username rules, and feed and board limits. | One rate-limit path; no hard-coded limits. | E8, D3 |
| S14 | A random-handle endpoint, for the 🎲 button. | Saves porting the word lists. | D3 (the button is left out until then) |
| S15 | `sources` on a pub lists only public-facing credits (PubDB, OSM, Commons…), never internal ones such as Hopscout. | The app shows what it is sent. | C5 |
| S15b | A notifications endpoint (new followers, replies, pubs on your lists closing), and later APNs. | Social tab. | F7 |
| S17 | `maxRating` and `sortBy=rating_asc` on `/pubs` and `/pins`. | No way to find the worst-rated pubs. | B8 |
| S18 | `kinds=` (venue kind keys) on `/pubs` and `/pins`, and `q` matching kind labels. | No filtering or searching by type (taproom, oddity…). | B8 |
| S19 | Write responses carry the writer's XP gained and their `level`. | A level-up moment without device maths. | L4 |
| S20 | The short `level { key, name, emoji }` on review authors and feed entries. | Badges beside names. | L5 |

The surveys also found two bugs on the web side to pass on:
- `OwnerPicker` expects `/brands` to be a bare array, but it is `{ brands: [...] }`, so
  no brand chips ever show.
- The web never calls `DELETE /me` or `DELETE /me/avatar`.

## Decisions

Taken on 2026-11-26.

| # | Question | Decision |
|---|---|---|
| P1 | What does a pin look like? | The web's teardrop, coloured by state, with the **pint logo** as the glyph on every pin, for now. This supersedes D17 for pins; the app icon stays 🚢. The web is due to change to the same. |
| P2 | Base map? | **Apple Maps** for now, behind a swappable `MapBase`. If CARTO is ever used, it is the vector version. |
| P3 | Server asks? | Yes. An agent works them on the pubdb side; milestones wait rather than work around them. |
| P4 | Show `sources`? | Yes, supersedes part of D25, but public credits only (PubDB, OSM, Commons), never internal sources such as Hopscout (S15). |
| P5 | Map/List segmented control? | Dropped for the web's sheet with peek, half and full. Supersedes R2. |
| P6 | Side menu? | No. A **bottom tab bar**: Map, Social (leaderboard, following, notifications), then Lists and Me for now. The last two slots are open to change. |
| P7 | Sign-in? | Straight to **bearer tokens with PKCE**, skipping D19's cookie phase. The redirect is believed registered in WorkOS; D1 checks it. |
| P8 | Admin tools? | Left out for now. |

## Risks

- **`MKMapView` instead of SwiftUI `Map`** is more code. It is the only first-party way
  to draw 5,700 dots smoothly. B2 deliberately lands it with no pins first.
- **Server asks may take time.** The order above puts the unblocked work first. If an
  ask is refused, the fallback is a named, tested client helper, agreed with you
  first.
- **WorkOS setup** (redirect and client id) is outside this repo and gates Phase D.
- **Production is a Pi.** Pins are about 155 KB gzipped per minute per phone, mostly
  answered 304. Fine at TestFlight scale.
