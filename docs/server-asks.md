# Server asks from the iOS app

**For:** whoever works on the PubDB server (`../pubdb`), person or agent.
**From:** the iOS parity plan ([parity-plan.md](parity-plan.md), "Server asks").
**Written:** 2026-11-26, against `spec/pubdb-api-v1.md` as checked on 2026-11-08.

The spec's own rule is that a client must be able to draw the whole UI without parsing
a string, doing date maths or knowing OSM `opening_hours` syntax. The web client still
breaks that rule in the places below, and iOS would have to copy it. Each ask moves that
logic onto the server once, so neither client has it.

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

### S15b. Notifications [F7]

There is nothing to build against yet. Sketch:
- `GET /api/v1/notifications` returns `{ items: [{ id, kind, title, body, pub?, user?, createdAtLabel, read }], unread }`.
- Kinds include a new follower, and a pub on your hit list or Been here closing.
- Later: APNs device registration (`PUT /api/v1/me/devices`).

## Bugs found in the web client while surveying

- `OwnerPicker` expects `GET /api/v1/brands` to return a bare array, but it returns
  `{ brands: [...] }`, so no brand chips ever show. There is also an unused
  `KNOWN_OPERATORS` in `forms.tsx`.
- The web has no UI for `DELETE /api/v1/me` (delete account), which the App Store
  requires of the iOS app, or for `DELETE /api/v1/me/avatar`.
- A malformed `lon` reports `field: "lat"`.
