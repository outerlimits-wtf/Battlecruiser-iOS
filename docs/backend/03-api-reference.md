# 3. API v1 reference

The authoritative contract is **`spec/pubdb-api-v1.md`** on the backend branch
`chore/latest-close-and-prettier`. This document is the iOS-focused version of it. It
concentrates on the endpoints the MVP uses and records **where production differs from
the spec**. Those differences were checked against `https://pubdb.outerlimits.wtf` on
2026-10-16.

## Conventions

- **Base URL:** `https://pubdb.outerlimits.wtf/api/v1`, or `http://localhost:3000/api/v1`
  when running the backend yourself.
- **Reads are public.** No headers, no key, no login.
- **Always send `at`**: the device's current time as a full ISO-8601 instant with its
  offset, e.g. `2026-10-16T22:30:00+01:00` (in a URL the `+` must be encoded as `%2B`).
  It is the moment the server reasons from for "open now", "tonight" and "closes in 40
  minutes". If you leave it out the server uses its own clock, which is usually right and
  wrong exactly when it matters.
- **Send `lat` and `lon`** (the user's location) when you have it, to get `distance` on
  each pub.
- **Pub ids contain a slash**: `node/123`, `way/456`. In a path it must be `%2F`
  (doc 4 has the Swift).
- **`null` means "we don't know".** It never means zero or false.
- **Ignore unknown keys.** New fields appear without a version bump. Swift's
  `Decodable` already does this, so don't add strict checks.
- **Labels are ready to show.** Fields ending `Label`, `formatted`, `label` and
  `displayValue` are written for people in `en-GB`. Show them as sent. Don't build the
  same strings yourself.
- **Errors:**

  ```json
  { "error": { "code": "invalid_request", "message": "at must be an ISO 8601 instant", "field": "at" } }
  ```

  Switch on `code`: `invalid_request` 400, `not_authenticated` 401, `not_found` 404,
  `duplicate_value` 409, `rate_limited` 429 (with `retryAfter` seconds), `server_error`
  500. `message` is safe to show to a user. `field` is present only when one input was
  at fault.
- **A wrong path returns HTML, not a 404.** Anything the server doesn't recognise falls
  through to the web app's page with `200 text/html`. Treat a non-JSON `Content-Type` as
  an error.
- **Rate limit:** 300 reads a minute per client.

## Endpoints

| Method | Path | MVP? | Purpose |
|---|---|---|---|
| GET | `/meta` | ✅ | Labels, symbols, limits. Fetch at launch and cache. |
| GET | `/pubs` | ✅ | Pubs in an area, or a search |
| GET | `/pubs/{id}` | ✅ | One pub in full |
| GET | `/pubs/{id}/similar` | ✅ (nice to have) | Up to 6 nearest other places |
| GET | `/me` | later | Who is signed in. Always 200, `user: null` when signed out. |
| PATCH | `/me` | later | Change your handle |
| GET | `/feed` | later | Latest contributions and reviews across all pubs |
| GET | `/leaderboard` | later | Top contributors |
| GET | `/brands` | later | Brand names in use, for an autocomplete |
| GET | `/watchlist` · PUT/DELETE `/pubs/{id}/watch` | later | Your starred "hit list". Signed in only, reads included. |
| POST | `/pubs/{id}/contributions` · DELETE `…/{contributionId}` | later | Report or retract a fact. Signed in. |
| POST | `/pubs/{id}/reviews` · DELETE `…/{reviewId}` | later | Review (1–10) or remove one. Signed in. |

Admin tools live under `/admin/*` and the sign-in pages under `/auth/*`, outside `/api`.
The app ignores both.

---

## `GET /meta`

Everything the UI would otherwise hard-code: amenities, features, weekdays, contributable
fields, limits. Each amenity and feature has a **symbol** (below).

```json
{
  "amenities": [ { "key": "pub", "label": "Pub",
                   "symbol": { "key": "amenity.pub", "type": "emoji", "emoji": "🍺", "url": null } } ],
  "features":  [ { "key": "garden", "label": "Garden",
                   "symbol": { "key": "feature.garden", "type": "emoji", "emoji": "🌳", "url": null } } ],
  "weekdays":  [ { "day": 0, "short": "Mon", "long": "Monday" } ],
  "contributableFields": [ { "key": "guinness_price", "label": "Guinness price", "kind": "price",
                             "min": 200, "max": 1500, "corroborating": true } ],
  "limits": { "maxLimit": 2000, "defaultLimit": 500, "minRating": 1, "maxRating": 10, "…": "…" }
}
```

### Symbols

Anything drawn with an icon (amenity, feature, status, tonight marker) comes as:

```json
{ "key": "feature.vinyl", "type": "icon", "emoji": "💿", "url": "https://…/vinyl.4f1a9c2e.png" }
```

How to draw one, in order:

1. If the app bundles artwork named after `key` (e.g. an asset called
   `feature.vinyl`), draw that.
2. If not, and `url` is set, show `emoji` straight away and swap in the image when it
   loads.
3. Otherwise draw `emoji`. It is always present.

Never key a cache on `url` (it changes when the artwork does), and never wait for an
image before drawing. **For the MVP, drawing `emoji` alone is a correct client**, which
is what the spec intends. Bundled artwork can come later.

---

## `GET /pubs`

| Param | Example | Notes |
|---|---|---|
| `at` | `2026-10-16T22:30:00%2B01:00` | Always send |
| `lat`, `lon` | `51.5098`, `-0.1257` | Adds `distance`. **Does not change the sort order** (see below). |
| `bbox` | `-0.135,51.505,-0.120,51.515` | **`west,south,east,north`**: longitude first. The visible map region. |
| `amenity` | `pub` | `pub` or `bar`. **Send `pub` explicitly**, because production returns both by default. |
| `q` | `red lion` | Substring search on name, address, postcode, city |
| `openNow` | `1` | Only places open at `at` |
| `features` | `garden,darts` | All must be `yes` |
| `openOnDay`, `opensBefore`, `closesAfter`, `minRating`, `hasHours`, `hasPhoto`, `listed`, `maxGuinnessPrice`, `status` | | Filters. See the spec. Invalid values are ignored rather than rejected. |
| `limit` | `200` | Default 500, max 2000 |

Response:

```json
{ "pubs": [ PubSummary, … ], "count": 53 }
```

**Order:** with `bbox`, nearest to the **centre of the box** first, roughly measured.
Without it, alphabetical. The app should re-sort for display (doc 4).

**Size:** about 1 KB per pub before compression. 500 pubs is about 0.5 MB.

### `PubSummary`

The shape and keys are exactly what production sends. The values are mixed from several
pubs so that every field is filled in.

```json
{
  "id": "node/269253652",
  "name": "The Harp",
  "amenity": { "key": "pub", "label": "Pub",
               "symbol": { "key": "amenity.pub", "type": "emoji", "emoji": "🍺", "url": null } },
  "lat": 51.5098, "lon": -0.1257,
  "address": "47 Chandos Place", "postcode": "WC2N 4HS", "brand": null,
  "distance": { "metres": 20, "label": "20 m" },
  "status": { "key": "open", "label": "Open",
              "symbol": { "key": "status.open", "type": "emoji", "emoji": "🍺", "url": null },
              "serving": true, "permanent": false, "since": null, "became": null },
  "open": { "state": "open", "label": "Closes 01:00", "closesAt": 60, "closesAtLabel": "01:00",
            "minutesUntilClose": 150, "countdownLabel": "2h 30m", "closingSoon": false },
  "tonight": { "kind": "kicked_out", "label": "Out 24:40",
               "symbol": { "key": "night.kicked_out", "type": "emoji", "emoji": "🚪", "url": null },
               "minutes": 1480, "reports": 3 },
  "guinness": { "pence": 695, "formatted": "£6.95", "reports": 1,
                "updatedAt": "2026-08-07T20:57:33.708Z", "agoLabel": "2 months ago" },
  "rating": 8.4, "reviewCount": 11,
  "photo": { "url": "…", "thumbUrl": "…", "attribution": "…", "license": "CC BY-SA 4.0", "descriptionUrl": "…" },
  "features": [ { "key": "garden", "label": "Garden",
                  "symbol": { "key": "feature.garden", "type": "emoji", "emoji": "🌳", "url": null } } ],
  "listed": false
}
```

What matters for the map and list:

- **`open.state`**: `open` / `closed` / `unknown`. Draw open pins prominently. **Draw
  `unknown` as neither open nor closed.** `open.label` is the pill text.
- **`open.minutesUntilClose`** is what to count down from. Never subtract `closesAt` from
  the clock: `closesAt: 60` means 01:00, and past midnight that subtraction gives a
  negative number.
- **`tonight`**: when people are actually turned out, or else last orders. `null` if
  nobody has reported either. Show `label` as sent, including "24:40".
- **`status.serving`** is false for a pub that has closed down or is shut for now.
  Branch on `serving`/`permanent`, not on `status.key`.
- **`features`** lists only the `yes` ones.
- **`photo.attribution` and `license`** must be shown wherever the photo is.

## `GET /pubs/{id}`

```
GET /api/v1/pubs/way%2F558503742?at=2026-10-16T22:30:00%2B01:00&lat=51.5098&lon=-0.1257
```

Returns a `PubDetail`: every `PubSummary` field plus the following. The keys match
production; some values are illustrative.

```json
{
  "description": null, "city": "London", "operator": "Fuller's", "brewery": null,
  "checkedAt": null, "lastScrapedAt": "2026-08-01T00:00:00.000Z",
  "contact": { "phone": "+44 20 7836 0291", "website": "https://…", "email": null,
               "facebook": null, "instagram": null },
  "hours": { "raw": "Mo-Sa 11:00-23:00; Su 12:00-20:00", "source": "osm",
             "attribution": { "kind": "source", "label": "OpenStreetMap", "sourceKey": "osm" } },
  "weekTable": [
    { "day": 4, "dayLabel": "Fri", "dayLongLabel": "Friday", "isTonight": true,
      "doorSays": "11:00–23:00", "bell": null, "out": null }
  ],
  "gardenCloses": null,
  "priceHistory": { "points": [ { "pence": 480, "at": "…", "formatted": "£4.80" } ],
                    "minPence": 480, "maxPence": 620 },
  "timeline": [ { "name": "The Harp", "fromLabel": "1995", "untilLabel": null, "owner": null, "isCurrent": true } ],
  "features": [ { "key": "darts", "label": "Dart board", "value": "no", "symbol": { "…": "…" } } ],
  "heritage": null,
  "reviews": [ { "id": 12, "rating": 8, "body": "…", "createdAt": "…", "createdAtLabel": "2 Jun 2026",
                 "attribution": { "kind": "user", "label": "@alex", "sourceKey": null } } ],
  "contributions": [ { "id": 88, "field": "guinness_price", "fieldLabel": "Guinness price",
                       "value": "620", "displayValue": "£6.20", "createdAt": "…", "createdAtLabel": "11 Jul 2026",
                       "attribution": { "kind": "source", "label": "PubDB", "sourceKey": "Hellcat" } } ],
  "sources": [ { "key": "osm", "label": "OpenStreetMap", "url": "https://www.openstreetmap.org/way/558503742" } ],
  "osmTags": { "…": "…" }
}
```

- **`weekTable`** always has seven rows, Monday first. `doorSays` is the opening-hours
  text. `bell` and `out` are `{minutes, label, reports, latestAt, latestLabel}` or `null`.
  The row with `isTonight: true` is tonight's session, so the app never works out
  which day it is.
- **`sources`** must be shown (licence condition).
- `404 not_found` for an unknown id. The response is about 5 KB.

## `GET /pubs/{id}/similar`

`{ "pubs": [ PubSummary, … ] }`: up to six nearest other places. Despite the name, it
does not measure similarity.

---

## Spec vs production (as of 2026-10-16)

The spec says it is tested against the code. In these places the code, and therefore
production, does not yet do what the spec says. **Build against production behaviour**,
and write the code so that each will still work if the server catches up.

| Topic | Spec says | Production does | What the app should do |
|---|---|---|---|
| List response | `{pubs, page: {nextCursor, hasMore}, counts: {returned, open}}` | `{pubs, count}` | Make `page`/`counts` optional in the model. Count open pubs yourself from `open.state`. |
| List order | Open, then unknown, then closed, each by distance; `sortBy=distance` is the default | Distance from the **bbox centre**, or by name with no bbox | Sort on the device: by `open.state` rank, then `distance.metres`. |
| `amenity` default | `pub` | Both pubs and bars | Always send `amenity=pub` unless the user asks for bars. |
| `bbox` order | `south,west,north,east` | **`west,south,east,north`** (and so does the web app) | Send `west,south,east,north`. Ask the backend author to fix the spec. |
| `ETag` / `304` on detail | Yes | No `ETag` header | Don't rely on it. Cache yourself (doc 4). |
| Paging (`cursor`) | Yes | Not implemented | Use `bbox` plus `limit`. |
| `/regions`, `/stats` | Under `/api/v1` | Moved to `/admin` (`/api/v1/stats` returns the web page) | Not needed. |
| `/me` when signed out | `{authRequired, user: null}` | Same, plus a `session` diagnostics object | Ignore `session`. |

---

## Swift model sketch

A starting point, not compiled. Every type is `Decodable` and ignores unknown keys.
Dates are kept as `String`, because the API mixes full timestamps and plain dates and
always sends a display label next to them.

```swift
struct Symbol: Decodable, Hashable {
    let key: String
    let type: String          // "emoji" | "icon" | future values — don't switch exhaustively
    let emoji: String         // always present
    let url: URL?
}

struct Labelled: Decodable, Hashable {   // amenity, feature (summary)
    let key: String
    let label: String
    let symbol: Symbol
}

struct PubSummary: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let amenity: Labelled
    let lat: Double
    let lon: Double
    let address: String?
    let postcode: String?
    let brand: String?
    let distance: Distance?
    let status: Status
    let open: OpenInfo
    let tonight: Tonight?
    let guinness: Guinness?
    let rating: Double?
    let reviewCount: Int
    let photo: Photo?
    let features: [Labelled]
    let listed: Bool

    struct Distance: Decodable, Hashable { let metres: Int; let label: String }

    struct Status: Decodable, Hashable {
        let key: String; let label: String; let symbol: Symbol
        let serving: Bool; let permanent: Bool
        let since: String?; let became: String?
    }

    struct OpenInfo: Decodable, Hashable {
        enum State: String, Decodable { case open, closed, unknown }
        let state: State
        let label: String
        let closesAt: Int?
        let closesAtLabel: String?
        let minutesUntilClose: Int?
        let countdownLabel: String?
        let closingSoon: Bool
    }

    struct Tonight: Decodable, Hashable {
        let kind: String          // "kicked_out" | "last_orders"
        let label: String
        let symbol: Symbol
        let minutes: Int
        let reports: Int
    }

    struct Guinness: Decodable, Hashable {
        let pence: Int; let formatted: String; let reports: Int
        let updatedAt: String; let agoLabel: String
    }
}

struct Photo: Decodable, Hashable {
    let url: URL; let thumbUrl: URL
    let license: String?; let attribution: String?; let descriptionUrl: URL?
}

struct PubList: Decodable {
    let pubs: [PubSummary]
    let count: Int?
}

struct APIErrorBody: Decodable {
    struct Detail: Decodable { let code: String; let message: String; let field: String? }
    let error: Detail
}
```

`PubDetail` includes every summary field. The simplest way to decode it is a struct
that decodes a `PubSummary` from the same decoder (`summary = try PubSummary(from:
decoder)`) and then its own extra keys (`contact`, `hours`, `weekTable`, `timeline`,
`features` with `value`, `reviews`, `contributions`, `sources`, `priceHistory`). Note
that `features` has a different shape in detail: each entry has a `value`. Decode it in
the detail type, not the summary.

`OpenInfo.State` as a closed enum will fail to decode if the server ever adds a fourth
state. If you want to be defensive, decode it as a `String` and map unknown values to
`.unknown`.
