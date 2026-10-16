# 4. Serving the iOS client

How the MVP (a read-only map of pubs on MapKit, iPhone first) talks to the backend, and
what comes later. Decisions behind this are in [doc 5](05-decisions.md).

## The short version

**The MVP needs nothing from the backend that it doesn't already do.** Production
serves the v1 API publicly, without a login, as JSON. The server works out open/closed
state, countdowns, "tonight", prices, distances and every display string. The app's job
is to:

1. ask for the pubs in the visible map region,
2. draw them,
3. show a pub's detail when one is tapped,
4. be honest about how old what it shows is.

## 1. Networking layer

One small `APIClient` (an `actor` or a `Sendable` struct over `URLSession`), with first-party
code only:

- **Base URL from the build configuration.** Debug and Release both point at production
  for now (reads are public and harmless). Keep it in an `.xcconfig` or `Info.plist` key
  so a local backend is one change away.
- **Every request carries `at`**, built with `Date.now.ISO8601Format()`. That gives UTC
  with a `Z`, which counts as "a full instant". Encode the query with `URLComponents` and
  `URLQueryItem` so `+` and `:` are escaped correctly.
- **Pub ids in paths**: encode the slash.

  ```swift
  let allowed = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
  let encoded = id.addingPercentEncoding(withAllowedCharacters: allowed)!   // node/123 → node%2F123
  // Then build the URL via URLComponents.percentEncodedPath, so it is not encoded twice.
  ```

- **Check the response before decoding.** A non-2xx response means decoding
  `APIErrorBody` and switching on `error.code`. A `Content-Type` that is not
  `application/json` means "wrong path or something in between". The server answers
  unknown paths with its web page and a `200` (doc 3).
- **Cancellation.** When the map moves again before a request finishes, cancel the old
  `Task`. `URLSession`'s async APIs stop the request when the task is cancelled.
- **Don't flood it.** The server allows 300 reads a minute per client and runs on a
  Raspberry Pi. Fetch when the map **stops** moving, not while it moves (below).

## 2. The map (MapKit, SwiftUI)

Available on iOS 17 and later, so fine for an iOS 18 minimum:

- `Map(position:)` with `Annotation` or `Marker` for each `PubSummary`.
- `.onMapCameraChange(frequency: .onEnd) { context in … }` fires once the user stops
  panning. Turn `context.region` into a bbox:

  ```swift
  let r = context.region
  let west  = r.center.longitude - r.span.longitudeDelta / 2
  let east  = r.center.longitude + r.span.longitudeDelta / 2
  let south = r.center.latitude  - r.span.latitudeDelta / 2
  let north = r.center.latitude  + r.span.latitudeDelta / 2
  // bbox=west,south,east,north   ← longitude first; the spec has this wrong, production is right
  ```

- Add a short debounce (≈300 ms) on top, and skip the fetch if the new region is inside
  the last one fetched at a similar zoom.
- **`limit` around 150–250.** Zoomed out over London, the box holds thousands of pubs.
  The server returns the ones nearest the box centre, which is a reasonable "what's
  here" sample. Do not ask for 2000.
- **Clustering**: SwiftUI's `Map` does not cluster annotations. If pins overlap badly
  when zoomed out, the first-party answer is `MKMapView` wrapped in a
  `UIViewRepresentable`, with `clusteringIdentifier`. Start with SwiftUI `Map` and the
  limit above. Move to `MKMapView` only if clutter becomes a real problem.
- **Order and emphasis on the device.** Production does not sort open-first (doc 3).
  Sort with `open.state` rank (open → unknown → closed), then `distance.metres`. Draw open
  pins large and coloured, `unknown` neutral, closed small and grey. This uses only values
  the server sent; it computes nothing.
- **User location**: `CLLocationManager` with when-in-use permission
  (`NSLocationWhenInUseUsageDescription` in Info.plist). Pass `lat`/`lon` with each
  request to get `distance`. If permission is refused, still work, without distances.
- **Attribution** (licence conditions, not optional): "© OpenStreetMap contributors"
  must be visible on or near the map, because the pub data is OSM-derived even on Apple's
  tiles. Photo `attribution`/`license` must go wherever a photo appears, and the pub's
  `sources` list in the detail view.

## 3. Pub detail

On tap, show a sheet straight away using the `PubSummary` you already have (name, open
pill, tonight, price), and fetch `GET /pubs/{id}` to fill in the rest: week table,
contact, timeline, reviews, sources. That way the sheet never opens empty.

For the MVP the detail is read-only. The **Contribute**, **Review** and **Star** buttons
are later work (§7).

## 4. "Open now" goes stale

`open`, `tonight`, `countdownLabel` and `agoLabel` are correct for the `at` that was
sent. They do not update themselves. A list fetched at 22:50 will still say "Closes 23:00,
10 min" at 23:20.

To keep them honest without computing anything:

- **Refetch on return to the foreground** (`scenePhase` becomes `.active`) and on a
  timer while the map is visible. Every 5 minutes is plenty, or every minute when
  any visible pub has `closingSoon: true`.
- **Show how old the data is** whenever it came from a cache or is more than a few
  minutes old: "as of 22:41". The 1am user's worst outcome is walking to a pub the app
  said was open.

(Counting `minutesUntilClose` down on the device is tempting and easy, but the spec
asks clients not to do time arithmetic. Refetching keeps one source of truth.)

## 5. Persistence: what to keep on the phone

**Your instinct is right: this app does not need a database for the MVP.** The server
owns all the data. The app is a window onto it.

**What SwiftData is for.** SwiftData (and Core Data before it) is an *object store with a
query engine*. You define model classes, it keeps them in SQLite on the device, and you
can query, filter, sort, relate and change them locally, with optional iCloud sync. It
earns its place when **the app owns data**: notes, a to-do list, anything the user creates
and edits. It also earns it when the app has to **search and filter a large dataset
without the network**.

**Why it is the wrong tool here (for now):**

- The data belongs to the server and changes there. A local copy needs code to merge
  updates and evict stale data, which is the hard part of any cache.
- Much of the data **depends on time**. `open.state` is only true for the `at` it was
  computed for. A stored "open" is a lie an hour later, so keeping it in a database
  gives it a permanence it doesn't have.
- Every new server field means a model change, and possibly a migration, for no benefit.
- Filtering and sorting are already the server's job.

**What to keep instead:**

| What | Where | Why |
|---|---|---|
| Decoded results for this session | In memory: an `@Observable` store holding the current list, plus a dictionary of opened details keyed by id | Instant back-navigation, no repeat fetches |
| `/meta` response | Raw JSON `Data` in `Caches/`, refreshed at launch | Labels and symbols available before the network answers |
| Last list and recently opened details (say the last 50) | Raw JSON `Data` in `Caches/`, one file each, with the time fetched | Opening the app on one bar of signal shows *something* straight away, marked "as of 22:41", then refreshes |
| Small preferences: last map region, "show bars" | `UserDefaults` / `@AppStorage` | Trivial values |
| Sign-in session (later) | Keychain | It is a credential |

Keeping the **raw response bytes** rather than re-encoding Swift structs means the cache
can't get out of step with the decoder. You decode the file exactly as you would a
network response. `Caches/` is the right place because iOS may clear it under storage
pressure, and the app must cope with that anyway.

`URLCache` (the HTTP cache built into `URLSession`) would do some of this automatically,
but only when the server sends caching headers, and it doesn't. A hand-written file
cache is about 50 lines and does exactly what you want.

**When SwiftData would earn its place later:**

- a hit list or favourites that must work offline and sync (although v1 stores the
  hit list on the server, per account)
- downloading **all of London** (about 5,300 pubs, a few MB) for full offline use with
  local filtering
- queuing contributions made without signal, to send later

None of these is in the MVP. Each could be added without changing the networking layer.

## 6. Running the backend locally (optional)

You don't need this for the MVP, because production is public. It is useful for testing
against data you control, or when production is down.

```bash
gh repo clone outerlimits-wtf/pubdb ~/Documents/Dev/pubdb-v1 -- --branch chore/latest-close-and-prettier
```

```bash
cd ~/Documents/Dev/pubdb-v1 && bun install && bun dev
```

- It needs Bun (`curl -fsSL https://bun.sh/install | bash`).
- **The database is not in git.** Ask the backend author for a snapshot (the backup
  script makes ~1.2 MB `.sqlite.gz` files), or build one with the scrape script (slow,
  public data only).
- With no WorkOS settings, writes are open locally, which is handy for trying
  contributions later.
- The Simulator reaches the Mac at `http://localhost:3000`. A physical device needs the
  Mac's LAN address, `PUBDB_HOST=0.0.0.0`, and an App Transport Security exception for
  plain `http` in Debug only.

## 7. Later: signing in and contributing

Writes on v1 need a signed-in session. Sign-in is built for the **web**:

1. The browser goes to `/auth/sign-in`, which redirects to WorkOS (Google or email code).
2. WorkOS redirects back to `/auth/callback` on the PubDB domain.
3. The server sets an encrypted **`pubdb_session` cookie**, and the browser sends it with
   every request from then on.

A native app can't simply use this. `ASWebAuthenticationSession` keeps its cookies in a
separate cookie jar from `URLSession`, so the cookie set at step 3 never reaches the
app's API calls. Two routes, to decide when contributions are on the roadmap:

- **No backend change (good enough for TestFlight):** run the sign-in flow in a
  `WKWebView` pointed at `/auth/sign-in`. When it lands back on the PubDB domain, read
  `pubdb_session` from `WKWebsiteDataStore.default().httpCookieStore` and copy it into
  `HTTPCookieStorage.shared` (or send it as a `Cookie` header), storing it in the
  Keychain. Google may refuse sign-in inside an embedded web view, so the email-code
  option would be the one to use.
- **Proper native support (needed for the App Store):** the backend accepts a native
  redirect (a universal link or custom URL scheme) and hands the app a token to send as
  `Authorization: Bearer …`. Apple also requires **Sign in with Apple** in an app that
  offers Google sign-in, which WorkOS supports but the backend would need to enable.
  This is backend work for its author, once they are back.

Everything else about contributions is ready on the server: `meta.contributableFields`
says which editor to show for each field (`price`, `night`, `tri`, …), validation
messages are written for users, and `displayValue` and `attribution` are pre-formatted.

## 8. Things to raise with the backend author (none blocks the MVP)

1. **Spec vs production differences** (doc 3): `bbox` order in the spec, the missing
   open-first ordering, the `amenity` default, `page`/`counts`, `ETag`. Either the code
   or the spec should change. As things stand, a client built from the spec would break.
2. **Merge the v1 branch into `main`**, or tell us which branch is the truth. It is
   81 commits ahead and is what runs in production.
3. **A native sign-in route** (§7), when contributions are planned.
4. **Caching headers** (`ETag`, `Cache-Control: max-age` on `/meta`), which would let
   `URLCache` do some of §5's work.
