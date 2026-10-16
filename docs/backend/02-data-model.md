# 2. The data model

> **How this relates to v1.** This document describes how the backend *stores and
> reasons about* data. Most of it happens inside the server. With the v1 API the iOS app
> receives the results: open or closed, labels, formatted prices, the weekly table. It
> never sees raw contribution rows or opening-hours strings it has to parse. It is still
> worth understanding, because it explains what the numbers the app shows mean, and why
> some of them can look odd (a closing time of "24:40").

## The tables

There are six SQLite tables. Two matter to a client, a third holds reviews, and the rest
are bookkeeping.

```
pubs                    one row per pub/bar, written by the scraper
 ├─ id  "node/123456"   ← the OpenStreetMap element id (type/number). Contains a slash!
 ├─ name, lat, lon, amenity ("pub" | "bar"), address, postcode, city
 ├─ phone, website, brewery, description, opening_hours (OSM syntax string)
 ├─ features            JSON text: {"garden":"yes","darts":"no",...}
 ├─ hygiene, heritage, photo, previous_names, osm_tags, sources   (JSON text blobs)
 └─ first_seen, last_scraped_at, checked_at, ...

contributions           one row per fact a drinker (or importer) reported
 ├─ id (integer), pub_id, field, value (always a string), author (nullable), created_at

reviews                 one row per review
 ├─ id (integer), pub_id, author, rating (1–5), body (nullable), created_at

scrape_runs, import_matches, import_aliases   ← admin bookkeeping, not for clients
```

Some general points about the storage:

- **Nested data is stored as JSON text inside columns** (`features`, `hygiene`,
  `photo`, …). The API turns it back into proper nested JSON before sending it, so the
  client never sees the raw text.
- **Dates are ISO-8601 strings** such as `2026-10-16T21:14:03.512Z` (UTC, with
  milliseconds). See doc 4 for why that matters to `JSONDecoder`.
- **Nothing is ever edited in place by a client.** Clients only *insert*
  contributions and reviews, and *delete* them.

## The central idea: a Pub is scraped data with contributions layered on top

This is the most important concept in the backend.

The `pubs` row holds what the outside world says (OSM and friends). The `contributions`
table holds what drinkers say. When the API builds a `Pub` to send you, it starts from
the row and **overlays the newest contribution for each field**:

```
                     scraped (pubs row)          contributions (newest wins)        → API value
name                 "Graveney and Meadow"       name = "Oberon"   (2 days ago)     → "Oberon"
phone                "020 1234 5678"             (none)                              → "020 1234 5678"
opening_hours        "Mo-Su 12:00-23:00"         opening_hours = "Mo-Th 12:00-23:00; Fr,Sa 12:00-01:00"
                                                                                     → the contributed one
features.garden      "unknown"                   garden = "yes"                      → "yes"
```

Because of this:

- **To correct something you delete the contribution, not edit it.** Remove the
  newest `name` contribution and the previous one, or the scraped value, shows through
  again. There is no update endpoint, and there is no history of deletions.
- **New kinds of user data are new `field` values, not new columns.** The backend author
  can add a field without a database migration, and you get it as a new key in the
  `Pub` JSON.
- **Some fields are *aggregated* rather than "newest wins"**: Guinness price, last
  orders and kicked out. Details below.

The fields a client may contribute (`CONTRIBUTABLE_FIELDS` in `src/lib/types.ts`):

| Field | Value format | Rule |
|---|---|---|
| `garden`, `real_ale`, `craft_beer`, `food`, `live_music`, `sports_tv`, `pool_table`, `darts`, `open_fire`, `vinyl` | `"yes"`, `"no"` or `"unknown"` | newest wins |
| `opening_hours` | OSM opening-hours syntax, e.g. `Mo-Th 12:00-23:00; Fr,Sa 12:00-01:00` | newest wins |
| `website`, `phone`, `description`, `brewery`, `brand` | free text, max 2000 chars | newest wins |
| `name` | free text, max 120 | newest wins |
| `amenity` | `"pub"` or `"bar"` | newest wins |
| `photo_url` | `http(s)://` URL, max 500 | newest wins (replaces the scraped photo) |
| `garden_closes` | free text (e.g. `"21:00"`) | newest wins |
| `previous_name` | `Name \| year \| owner`, year and owner optional | appended to the name history |
| `guinness_price` | whole **pence** as a string, `"200"`–`"1500"` | aggregated (see below) |
| `last_orders`, `kicked_out` | `"Thu 23:15"`: weekday + 24h time | aggregated per night (see below) |

**Duplicates:** for "newest wins" fields, sending the value the pub already has returns
`409 Conflict`. For the three aggregated fields a repeat is *corroboration*, so it is
accepted.


## Domain rules you need to understand

Each rule below ends with **"In v1:"**, describing what the app actually receives.

### Features are three-valued

Each of the ten features is `yes`, `no` or `unknown`, never a boolean. "Unknown" is the
honest default, and it is different from "no". The ten are garden 🌳, real ale 🛢️, craft
beer 🍺, kitchen 🍴, live music 🎸, live sports 📺, pool table 🎱, dart board 🎯, open fire
🔥 and vinyl 💿. The list changes over time: features are retired by deleting them.

**In v1:** a `PubSummary` lists only the features that are `yes`, already labelled and
ordered, each with a `symbol` (doc 3). `PubDetail` lists all of them with a `value` of
`yes`/`no`/`unknown`. `GET /api/v1/meta` lists the full set, so the app never hard-codes
the ten.

### Money is integer pence

Prices are stored and sent as whole pence: `620` means £6.20.

**In v1:** every price comes with a `formatted` string (`"£6.20"`). Display that, and keep
`pence` for sorting or comparing.

### The Guinness price

The current price is **not an average**. It is:

1. the **most frequently reported** price in the last 90 days,
2. with ties going to the most recent,
3. falling back to the single newest report if nobody has reported in 90 days.

Reports outside £2–£15 are rejected.

**In v1:** `guinness: {pence, formatted, reports, updatedAt, agoLabel}` or `null` when
nobody has reported one. `PubDetail.priceHistory` has the points for a chart.

### Last orders and kicked out: "the night the session started"

This is the subtlest rule in the codebase.

Opening hours say when the licence allows serving. Drinkers report what actually
happens: when the bell went (`last_orders`) and when they were turned out
(`kicked_out`). A report is a string like `"Thu 23:15"`.

**The day is the night the evening *started*.** If you are turned out at 00:20 on Friday
morning after a Thursday night, the report is `"Thu 00:20"`, not `"Fri 00:20"`.

Any time before **06:00** counts as the small hours of the previous evening, so it is
stored as `minutes + 1440`. `"Thu 00:20"` therefore becomes 1460 minutes, shown as
**"24:20"**. That keeps the ordering right: 00:20 sorts after 23:00 instead of 18 hours
before it. Each night's figure is the **median** of the last two years of reports, so one
lock-in until 3am does not skew it.

"Tonight" follows the same 06:00 rule: at 00:30 on Friday, tonight is still Thursday.

**In v1:** the server applies all of this. `PubSummary.tonight` is the single most useful
number at closing time. It is when people are turned out if anyone has reported it,
otherwise last orders, otherwise `null`. It comes with a ready-made `label` such as
`"Out 24:40"`. `PubDetail.weekTable` is the seven-night grid with `isTonight` marked.
**Show the labels as sent.** "24:40" is deliberate, and the spec says never to turn it
into "00:40".

### Opening hours and "open now"

Opening hours are stored as a string in OpenStreetMap's
[opening_hours](https://wiki.openstreetmap.org/wiki/Key:opening_hours) syntax, e.g.
`Mo-Th 12:00-23:00; Fr,Sa 12:00-01:00`. The server parses it (`src/lib/hours.ts`) and works
out open, closed or unknown for a given moment. Pub hours are UK wall-clock times, so the
server evaluates them in Europe/London, whatever time zone the phone is in.

**In v1:** `open: {state, label, closesAt, closesAtLabel, minutesUntilClose,
countdownLabel, closingSoon}`, worked out for the moment the app sends as `at`. `state`
is `open`, `closed` or `unknown`. **`unknown` means nobody knows the hours.** It must not
be drawn as open or as closed. The raw string is still in `PubDetail.hours.raw`, but the
app has no reason to parse it.

Because "open" depends on the clock, it goes stale. A list fetched at 22:50 does not
know the pub shut at 23:00. Doc 4 covers what to do about that.

### Status: is the pub still there?

v1 adds `status`: `open`, `temporarily_closed`, `closed`, `demolished` or `converted`.
That is "does this pub still exist", which is separate from tonight's opening hours. The
spec says to **branch on the two booleans, `serving` and `permanent`, never on
`status.key`**, because more states will be added. Dead pubs are left out of lists
unless asked for with `status=any`.

### Name history

Former names come from OSM edit history, the hand-kept notes, and drinkers' reports.
**In v1:** `PubDetail.timeline` is ready to draw. It starts with the current name
(`isCurrent: true`) and runs backwards, each stop with `fromLabel`/`untilLabel` years and
an owner.

### Photos and sources carry licence obligations

Most photos come from Wikimedia Commons under CC BY or CC BY-SA. **Showing the
`attribution` and `license` next to the photo is a legal condition of using it**, not
decoration. The pub data itself is from OpenStreetMap (ODbL), which requires
"© OpenStreetMap contributors" credit. That applies even when the pins are drawn on
Apple Maps. Some photos are hot-linked from pubs' own websites and are not openly
licensed.

**In v1:** `photo: {url, thumbUrl, license, attribution, descriptionUrl}` or `null`, and
`PubDetail.sources: [{key, label, url}]`. The spec says both clients **must** display
these.

### Who said so: attribution

Every contribution and review records who made it. On v1 that is a signed-in account
with a handle like `@damp_carpet`, or one of the backend's own importers, or a name typed
before accounts existed.

**In v1:** an `attribution: {kind, label, sourceKey}` object where `kind` is `user`,
`source` or `anonymous`. Show `label` exactly as sent. Do not show `sourceKey`, which is
there for auditing.

### Ratings are 1–10

Reviews were rated 1–5 until August 2026. The old ratings were deleted, not converted,
and the scale is now **1–10**. Read `limits.minRating`/`maxRating` from `/api/v1/meta`
rather than hard-coding it.

### Food hygiene

Food-hygiene ratings exist in the data. The roadmap plans to remove them, and the iOS
MVP leaves them out.
