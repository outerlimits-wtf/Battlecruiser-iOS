# Server asks from the iOS app

**For:** whoever works on the PubDB server (`../pubdb`), person or agent.
**From:** the iOS parity plan ([parity-plan.md](parity-plan.md), "Server asks").
**Written:** 2026-11-26, against `spec/pubdb-api-v1.md` as checked on 2026-11-08.

The spec's own rule is that a client must be able to draw the whole UI without parsing
a string, doing date maths or knowing OSM `opening_hours` syntax. The web client still
breaks that rule in the places below, and iOS would have to copy it. Each ask moves that
logic onto the server once, so neither client has it.

## Where they stand (2026-11-27)

**Deployed 2026-11-27.** S1–S10 and S12–S16 were built on `feat/ios-server-asks`,
fast-forwarded into pubdb's `main` and deployed (cb038eb). Later that day `main` gained
a test-isolation fix (efec76f) and the new levels (c344f56, below), also deployed.
`bun test` passes (765) on the Mac and on the Pi; `tsc` has one old error, in
`src/sources/website.ts:139`. The spec (`../pubdb/spec/pubdb-api-v1.md`) documents every
field below and is the source of truth. This section only records what was built and
where it differs from the ask.

| ask | commit | built as | differs from the ask |
| --- | --- | --- | --- |
| S1 | 638b6bd | `counts { returned, matched, open }`, `truncated`, `headerLabel`, `scopeLabel`; open → unknown → closed, nearest first; `sortBy=distance\|name` | adds `counts.matched` |
| S2 | 266ef8c | `weekTable[].state`, `weekTable[].sessions [{ open, close \| null }]`; `opening_hours` input `{ days: [{ day, state, sessions }] }`; `opening_hours` and `garden_closes` validated (`400`, `field: "value"`) | a day left out counts as closed; `close: null` is "onwards" |
| S3 | 5072e1e | `PubDetail.session { day, short, long }` (0 = Monday); night contributions take `{ "at": ISO }` | none |
| S4 | aab1137 | `editable[field] = { value, display }`; `contributableFields[]` gains `section`, `order`, `placeholder`, `maxLength`; kinds `status` and `weekday` | an unknown `kind` falls back to a text editor (spec rule) |
| S5 | 51f04df | `status` `{ state, year?, became? }`, `previous_name` `{ name, year?, owner? }`, **and** `parts [{ key, label, kind, optional }]` in meta; the piped form still accepted | both options, not one |
| S6 | 9f30427 | `timeline[]` gains `contributionId`, `canRemove`, `hideValue` | adds `hideValue`: post it as a `previous_name_removed` contribution to hide a stop that came from OSM |
| S7 | c2b50e3 | every label asked for; `priceHistory.window` also has `years [{ at, label }]`, `change { pence, label } \| null` | `priceHistory.window.to` is the midnight (London) ending `at`'s day, so ETags can match |
| S8 | fb2d46e | `meta.filters { ratingSteps, guinnessSteps }`; `appliedFilters` and `ignored [{ param, value }]` on `/pubs` and `/pins` | a missing `amenity` applies no filter (pubs and bars); now a spec "Known divergence". **Always send `amenity`** unless `kinds` is set |
| S9 | cb038eb | weak `ETag` and `304` on `/pubs/{id}` and `/meta`; the detail is `private, no-cache`, `Vary: Authorization, Cookie` | keep one tag per pub **per account** |
| S10 | d46bac4 | `PUT`/`DELETE /users/{u}/block` → `{ username, blocked }`; `GET /me/blocks`; profiles gain `isBlocked` | contributions stay visible; reviews, photos, quotes, feed entries, follows and notifications are hidden. They are never told |
| S12 | 3de6e96 | the `201` from contribution and review `POST`s adds `entry` (as in `contributions[]`/`reviews[]`) and `pub` (the full `PubDetail`); both take `at`, `lat`, `lon` | a `202` has neither key |
| S13 | a754371 | `Retry-After` on the photo 429; `limits` gains `maxReportNote`, `maxAvatarBytes`, `username { min, max, pattern }`, `feed`/`boards`/`notifications` `{ defaultLimit, maxLimit }`, `guinnessFilter { minPence, maxPence }` | adds notifications limits |
| S14 | db017ca | `GET /usernames/random` → `{ username, label }`, `no-store` | adds `label` |
| S15 | a5875f0 | `sources[]` only `osm`, `fhrs`, `wikidata`, `commons`, each with `license` (null for Commons) | none |
| S16 | 9e71aab | `level` on `/me` (`user.level`) and `/users/{u}`; leaderboard rows add `xp` and `level { key, name, emoji } \| null`; `/meta` `levels` and `xpRules` | `next` gains `key`; `progress` rounds down to two decimals; the leaderboard still ranks on `total`. Levels changed in c344f56, see below |

**Levels as live (c344f56):** six, with Owner retired, so Lock-in is the top.

| key | name | emoji | from XP | line |
| --- | --- | --- | --- | --- |
| `walk_in` | Walk-in | 🚪 | 0 | Never seen you before mate |
| `half_pinter` | Half Pint Hero | 🍺 | 50 | Just in for a swift one |
| `pub_crawler` | Pub Crawler | 🗺️ | 100 | Just passing through mate |
| `punter` | Punter | 🍻 | 500 | Knows where the toilets are |
| `regular` | Regular | 🥂 | 1000 | Staff know your order |
| `lock_in` | Lock-in | 🔒 | 1500 | Still here when the shutters come down |

The spec now says level keys can be retired as well as added: draw a level from its
own `name` and `emoji`, never from a table in the app.

**Still open:** S11 (no Apple team id yet), S17 and S18 (not asked for in that run),
the new S19 and S20 (levels in more places, below), S21 (the status states in
`/meta`) and S22 (a `time` kind), both asked 2026-11-27.
Retractions are the only stub left in the spec. S17 and S18 have no stub there yet.

**Not checked yet:** the web client's use of S10, S12 and S16 (levels, the `pub` a
write returns, Block/Unblock on profiles) is live but nobody has looked at it in a browser,
and nothing that needs signing in has been tried against production.
The web Profile still formats `joinedAt` itself rather than drawing `joinedAtLabel`.

## How to work these

- Change the spec first. Move a stub out of *Planned — not built* or add the new field
  to its payload section. Then build it, then add a contract test (`src/api/contract.test.ts`).
- **Only add things.** v1 is used by a shipped binary: no renames, no removals, no
  change to an existing field's meaning. New keys on existing objects are fine, because
  clients ignore keys they don't know.
- Once a field exists, use it in the web client too and delete the web's own version
  (paths are given below). Then the two clients can't drift.
- One ask per PR. The iOS milestone each one unblocks is in brackets.

## The asks, in the order iOS needs them

As first written on 2026-11-26. For what was built, see *Where they stand* above.

### S1. List ordering and counts on the server [B6]

Build the spec's stub *Server-side list ordering and counts* as written:
- `/pubs` orders open, then hours unknown, then closed, by distance from `lat`/`lon`
  within each group (the bbox centre when there is no origin).
- `sortBy` gains `distance` and `name`.
- Add `counts: { returned, open }`, counted over the whole match.
- Add `truncated: true` when more pubs matched than `limit`.

Web to delete: the re-sort and `openCount` in `src/App.tsx` (about lines 241–251), the
re-sort in `menu/HitList.tsx`, and the "pubs.length >= limit" check.

### S2. Hours that need no parsing [E6]

`components/panel/hours-editor.ts` parses `weekTable[].doorSays` display strings back
into times, then writes OSM syntax.
- Add `weekTable[].sessions: [{ open: "HH:MM", close: "HH:MM" }]` and
  `weekTable[].state: "open" | "closed" | "unknown" | null`.
- Accept a structured `opening_hours` contribution value, e.g.
  `{ "days": [{ "day": 0, "state": "open", "sessions": [...] }, ...] }` as a JSON string.
  Serialise it to OSM syntax on the server.
- Validate `opening_hours` and `garden_closes`, which accept anything today. Answer
  `400` with `field: "value"` when they don't parse.

### S3. Which night it is [E5]

The 06:00 cutoff (`lib/nights.ts` `sessionDay`, `formatNightValue`) runs on the client.
- Add `session: { day, short, long }` to the pub detail for `at`: the night a report
  made now belongs to.
- Let `last_orders` and `kicked_out` contributions also take `{ "at": "<ISO instant>" }`
  as their value, with the server working out the night and time.

### S4. Server-driven Fix panel [E4]

The web hand-wires every editor and prefills each one itself (`fields.ts`,
`currentTextValue`, `TEXT_FIELDS`, `FIELD_LABELS`).
- Add `editable: { [fieldKey]: { value: string | null, display: string | null } }` to
  the pub detail, with the current value of every contributable field: feature
  tri-states, amenity kind, status, quiz and karaoke days, `garden_closes` and so on.
- Add `placeholder`, `maxLength`, `section` (`details`, `features`, `tonight`,
  `history`, `listing`) and `order` to each `contributableFields` entry in `/meta`.
- Add a `weekday` kind for `quiz_night_day` and `karaoke_night_day`.
- List `status` among the kinds in the spec (the code already sends it).

### S5. No pipe-packed values [E4, E7]

`status` (`state | year | became`) and `previous_name` (`name | year | owner`) make
clients pack strings.
- Accept a JSON object as `value` for these, e.g.
  `{ "state": "converted", "year": 2019, "became": "Tesco" }`.
- Or publish their parts in `/meta` as `parts: [{ key, label, kind, optional }]`.
- Keep accepting the piped form for old clients.

### S6. Timeline entries say which contribution they are [E7]

`panel/History.tsx` matches timeline stops to `previous_name` contributions by
"name|until" to find what to delete or edit.
- Add `contributionId` and `canRemove` to every `timeline` entry that came from a
  contribution.

### S7. Labels the clients still build [B6, C3, C5, F3]

All of these are composed on the client today. Add each next to its raw value:
- `ratingLabel` ("8.4") beside `rating`, and a review's `ratingLabel` ("8/10")
- `createdAtLabel` on profile reviews, `joinedAtLabel` on profiles,
  `checkedAtLabel` and `lastScrapedAtLabel` on the detail
- `addressLine` ("23 High Path, Wimbledon, SW19 2JY")
- `contributorCount` and `contributorLabel` ("Crowd-sourced by 4 people")
- timeline `spanLabel` ("1988–1997", "since 1997")
- `priceHistory.band { minPence, maxPence, ticks: [{ pence, label }] }`,
  `priceHistory.window { from, to }`, and `priceHistory.summaryLabel`
  ("6 reports since Mar 2025", "▲ £0.40"); replaces `panel/price-scale.ts`
- `osmTags` as `osmFacts: [{ key, label, value, url? }]`, already filtered and humanised
  (replaces `fields.ts humaniseKey`)
- `hours.sourceLabel`
- `coverage.percentLabel` and per-area `percentLabel`
- leaderboard `summaryLines: [String]` (the footer sentences)
- on `/pubs`, `headerLabel` ("35 pubs · 12 open") and `scopeLabel`
  ("Near you, open ones first")

### S8. Filter options from the server [B8]

The rating chips (6+ to 9+) and Guinness price chips (£5.00 to £7.00) are hard-coded in
`Filters.tsx`.
- Add `filters: { ratingSteps: [...], guinnessSteps: [{ pence, label }] }` to `/meta`.
- On `/pubs` and `/pins`, echo `appliedFilters` (and `ignored: [...]`). Bad filter
  values are dropped silently today, so a client can't tell when one was ignored.

### S9. Conditional requests on `/pubs/{id}` and `/meta` [nice to have]

Build the spec's stub *Conditional requests* as written.

### S10. Block a user [G1, needed for the App Store]

Build the spec's stub *Block another user*. App Store Guideline 1.2 needs it before
submission. The open question (whether to filter a blocked person's contributions) is
the server's call.

### S11. Universal links [G2]

Serve `/.well-known/apple-app-site-association` on the web host with an `applinks`
entry for `/pub/*`. The app id comes from the iOS app's team id and bundle id once it
has a paid developer account (decision D15).

### S12. Writes return what they changed [nice to have, E1]

Contribution and review `POST`s return the raw stored row, with no `displayValue`,
`fieldLabel`, `attribution` or `canRemove`, so a client must refetch the pub.
- Return the presented entry, or the updated `PubDetail` under `pub`.

### S13. One rate-limit path, and every limit in `/meta` [E8, D3]

- The photo upload's daily-limit `429` has no `Retry-After`. Send one: the seconds until
  the oldest upload in the window is 24 hours old.
- Add to `limits` in `/meta`:
  - `maxReportNote` (500)
  - `maxAvatarBytes` (5 MB)
  - `username: { min: 2, max: 22, pattern: "^[a-z0-9_]+$" }`
  - feed and board default and maximum limits
  - the `maxGuinnessPrice` filter range

### S14. A random handle [D3]

`GET /api/v1/usernames/random` returns `{ username }`, already checked to be free.
This replaces porting `lib/username.ts randomUsername` and its word lists.

### S15. Only public sources [C5]

`sources` on a pub sometimes lists internal scrapers, such as Hopscout
(`lib/v1/attribution.ts`).
- Send only the credits a reader should see: PubDB, OpenStreetMap, Wikimedia Commons,
  the Food Standards Agency, Wikidata, and so on.
- Keep the licence-bearing ones (ODbL, CC BY-SA, OGL), because showing them is a
  condition of use.

### S15b. Notifications [F7] — done

Built on origin/main (4509cc4): inbox, read, settings, APNs devices. The app uses it.

### S16. Levels and XP [new]

People get a level from what they've added, each kind of thing worth different
XP. The server owns the weights and the thresholds, so they can be retuned
without a release and the web and the app always agree.

**Levels** as first asked (superseded: see *Levels as live* above):

| key | name | from XP | line |
| --- | --- | --- | --- |
| `walk_in` | Walk-in | 0 | Staff don't even know your order |
| `punter` | Punter | 100 | Knows where the toilets are |
| `regular` | Regular | 500 | They start pouring when you walk in |
| `lock_in` | Lock-in | 1500 | Still here when the shutters come down |
| `owner` | Owner | 5000 | Part of the furniture |

**XP per thing** (a starting point to tune):

| what | XP |
| --- | --- |
| a review with words | 25 (a score alone: 10) |
| a photo, once approved | 30 |
| opening hours | 20 |
| last orders / kicked out | 15 |
| a Guinness price | 15 |
| any other fact | 10 |
| a like on your review | 5 |

Facts taken back, or removed by an admin, take their XP with them. Importers
earn nothing.

**Shape.** A `level` object wherever a person is shown, and the tables in `/meta`
so a client can explain them:

```json
"level": { "key": "regular", "name": "Regular", "line": "They start pouring when you walk in",
           "emoji": "🍺", "xp": 640, "xpLabel": "640 XP",
           "next": { "name": "Lock-in", "atXp": 1500, "remainingLabel": "860 XP to Lock-in" },
           "progress": 0.14 }
```

- `GET /me` → `user.level`; `GET /users/{username}` → `level` beside `stats`.
- `GET /leaderboard` → each contributor gains `xp` and `level { key, name, emoji }`,
  and could be ranked on `xp` rather than `total`.
- `GET /meta` → `levels: [{ key, name, line, emoji, minXp }]` and
  `xpRules: [{ key, label, xp }]`.
- `next` is null at the top level; `progress` is 0–1 through the current level.

The iOS app draws `level` when it's there and nothing when it isn't, so this can
land on the server first.

### S17. The worst-rated pubs [B8, new]

Badly rated pubs are worth a look, but `/pubs` and `/pins` only take `minRating`.
- Accept `maxRating` (rated at most), so a client can ask for the 1s to 4s.
- Accept `sortBy=rating_asc` (and `rating_desc`), lowest first.

The app's rating chips now run 1+ to 9+; it adds a "Rated at most" row once
`maxRating` is accepted.

### S18. Filter and search by venue kind [B8, new]

`amenity` only takes the two groups, `pub` and `bar`, so there's no asking for
taprooms or oddities, and search only looks at name, address, postcode and city,
so "taproom" finds only places with it in the name.
- Accept `kinds=taproom,oddity` on `/pubs` and `/pins`: any of the venue kind keys
  in `/meta`'s `venueKinds`. Kinds cross the groups, so when `kinds` is set,
  ignore `amenity` (the app leaves it out).
- Have `q` match a venue kind's label too ("taproom", "taprooms", "oddity"), so a
  search for a type finds that type.

The app already sends `kinds` from its Type chips; until this lands the server
ignores it and, with no `amenity`, shows pubs and bars alike.

### S19. Writes say what they earned [L4, new]

So the app can mark a level-up without working out XP itself:
- The `201` from contribution, review and photo `POST`s adds `xp { gained, gainedLabel }`
  ("+25 XP") and the writer's `level` (the same object as on `/me`).
- Add `levelUp: true` when the write took them into a new level.

### S20. Levels beside names [L5, new]

Add the short `level { key, name, emoji }` (as on leaderboard rows) to review authors on
`PubDetail.reviews[]`, profile reviews and feed entries. Null for names with no account.

### S21. The status states in `/meta` [E4, H8, new]

The Fix panel's "Still there?" picker needs every state a pub can be in, but nothing
lists them: the spec names `open`, `temporarily_closed`, `closed`, `demolished`,
`converted`, `duplicate` and `broken` in prose, says more will be added, and the web
hard-codes them (`PUB_STATUSES`, `STATUS_LABELS`, `STATUS_EMOJI`, `LISTING_ERRORS`,
`isListingError` in `src/lib/types.ts`). Until this lands iOS copies the same seven.
- Add `statuses: [{ key, label, symbol, serving, permanent, listingError }]` to `/meta`,
  in the order a picker offers them. `label` and `symbol` as on `PubSummary.status`;
  `listingError` true for `duplicate` and `broken` (about the record, not the pub), so
  a client can draw "Still there?" and "Listing problem" apart.
- The `status` part of `status`'s `parts` (kind `status`) then means "a key from
  `meta.statuses`". Say so in the spec.
- Use it in the web's `FixControls` and delete the web's own lists.

### S22. A `time` kind for single times [H10, new]

`kind: hours` covers both a week (`opening_hours`) and a single time of day
(`garden_closes`, placeholder `21:30`, validated as a time). A client can't tell which
editor to draw without knowing the key, which is what `kind` exists to avoid. iOS picks
the week editor by key until this lands.
- Give `garden_closes` (and any future single time) `kind: time`: one `HH:MM`, 24-hour.
  Older clients fall back to a text editor (the spec's rule), which still works.
- Add `time` to the spec's list of kinds.

## For the web client

Changes the iOS app has made that the web should copy (not server work):

- **The sheet opens fully before it scrolls.** At half or peek, the panel and
  list don't scroll: a drag on the content moves the sheet, so it reaches full
  before any scrolling starts. Scrolling a half-open listing is never possible.
  iOS: `BottomSheet` (`DesignSystem/Sheet`), done 2026-11-26.
- **The pub photo runs to the sheet's top edge**, with the grabber drawn over
  it, instead of a white strip above it.

## Bugs found in the web client while surveying

- `OwnerPicker` expects `GET /api/v1/brands` to return a bare array, but it returns
  `{ brands: [...] }`, so no brand chips ever show. There is also an unused
  `KNOWN_OPERATORS` in `forms.tsx`.
- The web has no UI for `DELETE /api/v1/me` (delete account), which the App Store
  requires of the iOS app, or for `DELETE /api/v1/me/avatar`.
- A malformed `lon` reports `field: "lat"`.
