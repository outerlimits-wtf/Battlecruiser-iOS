# Test fixtures

`BattlecruiserKit/Tests/PubDBModelsTests/Fixtures/` holds real responses from the production PubDB v1 API
(`https://pubdb.outerlimits.wtf/api/v1`), captured on **2026-10-16** and re-captured with the
same requests on **2026-11-26** (the server had added venue kinds, `area`, photo galleries and
`quote`). Tests decode these to
prove the Swift models match what the server actually sends, rather than what the spec
says it sends (the two differ; see [backend/03-api-reference.md](backend/03-api-reference.md)).

`Package.swift` copies the folder into the `PubDBModelsTests` resource bundle
(`resources: [.copy("Fixtures")]`), and the tests load it with `Bundle.module`.
A new `.json` file dropped in here is picked up with no other changes.

The files are pretty-printed, but otherwise unchanged from the server: the same keys,
values and `null`s.

## The requests

Every request uses the same moment and the same user location, so the fixtures describe
one consistent evening:

- **`at`**: `2026-10-15T22:30:00+01:00` (Thursday 22:30 in London), except where noted
- **`lat`/`lon`**: `51.4431, -0.1525` (Balham)
- **list area**: `bbox=-0.165,51.420,-0.125,51.450` (Balham to Streatham), `amenity=pub`,
  `limit=60`

| File | Request | Status | Why it's here |
|---|---|---|---|
| `pubs-list-thu-2230.json` | `GET /pubs?{area}&at={Thu 22:30}&{loc}` | 200 | Balham's pubs on a Thursday evening: open and closing soon, Guinness prices, photos, `tonight` (Earl Ferrers). Since November every one has hours, so the unknown case lives in the sparse detail. |
| `pubs-list-fri-0130.json` | `GET /pubs?{area}&at=2026-10-16T01:30:00+01:00&{loc}` | 200 | The same area at 01:30, still Thursday's session: mostly `closed`, plus the past-midnight case |
| `pub-detail-earl-ferrers.json` | `GET /pubs/way%2F1223071579?…` | 200 | Non-null `tonight`, bell and kicked-out times in `weekTable`, a Guinness price, 12 contributions |
| `pub-detail-the-bedford.json` | `GET /pubs/node%2F251526423?…` | 200 | A photo with attribution, 2 reviews, Guinness price history (4 points) |
| `pub-detail-sparse-british-legion.json` | `GET /pubs/fhrs%2F925741?…` | 200 | As little as a pub can have: hours unknown, no photo, no features; venue kind `social_club`. **`hours` is an object whose fields are all `null`**, not `null` itself. (Replaced The Furzedown, which has since gained hours and a photo.) |
| `pubs-similar-the-bedford.json` | `GET /pubs/node%2F251526423/similar?…` | 200 | `{ "pubs": [...] }` with 6 summaries |
| `error-not-found.json` | `GET /pubs/node%2F1?…` | 404 | Error body without `field` |
| `error-invalid-at.json` | `GET /pubs?at=not-a-time` | 400 | Error body with `field: "at"` |
| `pins-pub-thu-2130.json` | `GET /pins?amenity=pub&at=2026-11-26T21:30:00+00:00` (captured 2026-11-26) | 200 | `application/geo+json` with a weak `ETag`. **Trimmed**: the full response is about 3,400 features (890 KB); this keeps the first 15 of each state (open, closing, unknown, closed), sorted by rank as the server sends them. Includes Brighton pubs, so coverage is wider than London. |
| `meta.json` | `GET /meta` (captured 2026-11-26, no `at`) | 200 | Every list the UI is driven by: amenities, venue kinds, features, weekdays, contributable fields and their kinds, boards, photo kinds, report reasons, `clients.ios.minVersion`, limits |

### After the server asks (2026-11-27)

Captured with the same requests on **2026-11-27**, after S1–S16 were deployed, and saved
beside the originals with a `-1127` suffix so the old shapes keep decoding too:
`pub-detail-earl-ferrers-1127`, `pub-detail-the-bedford-1127`,
`pub-detail-sparse-british-legion-1127`, `pubs-list-thu-2230-1127`, `meta-1127`,
`leaderboard-1127`, `profile-1127` (`GET /users/goatloaf`), `feed-1127` (`GET /feed`) and
`username-random-1127` (`GET /usernames/random`). They carry the new fields: `editable`,
`session`, `osmFacts`, the S7 labels, `counts`/`headerLabel`, `filters`, `levels`,
`summaryLines` and so on. `ServerAsksFixtureTests` decodes them; each Phase H step adds
checks for the fields it models.

Not captured: `/me` and `/me/blocks` need a signed-in session (curl without one gets
`{"user":null,"authRequired":true}`).

## Things to know

- **Earl Ferrers' night reports look like test data.** Last orders "10:30" and kicked out
  "Out 11:30", both reported at about 09:13 on 31 Jul 2026. They are still real, valid
  payloads, and useful because they are the only `tonight` values in the area. Don't read
  meaning into the times.
- **The server rejects some User-Agents.** Python's `urllib` got `403 Forbidden` from
  Cloudflare. curl and an iOS-style `CFNetwork` User-Agent get `200`. `URLSession` sends
  a CFNetwork User-Agent by default, so the app should be fine. If requests ever start
  failing with 403, look here first.
- **Refreshing.** Re-capture any time with the same requests via curl, then re-run the
  tests. Expect values (names, prices, open states) to change. The decoding tests should
  check shapes and the cases above, not exact numbers that are bound to drift.
