# 1. The big picture

## What the product is

PubDB is a crowd-sourced catalogue of British pubs. The backend author's notes describe
the one journey everything is judged against:

> It is 1am, you have been turned out of your pub, and you need somewhere that is still
> serving nearby.

That explains most of the design choices you will meet. *Open now* is the loudest thing
in the UI. Opening hours are treated with suspicion, so drinkers report when **last
orders** and **kicked out** actually happen. The Guinness price is "what you'll pay
tonight", not an average. Proper pubs are shown by default, with bars only when you ask
for them. And reading never asks you to sign in.

Longer term (`ROADMAP.md`) it wants to be a record of British pub culture as well: dead
pubs, name histories, old photos.

## The tools, translated

| Backend thing | What it is | Nearest iOS equivalent |
|---|---|---|
| **TypeScript** | JavaScript with a static type checker on top. Types are erased at runtime, so nothing *enforces* them on incoming JSON. The code validates input by hand instead. | Swift, minus runtime type safety. `interface Pub { … }` is a `struct Pub: Codable` that nothing checks. |
| **Bun** | The runtime that executes TypeScript: interpreter, package manager, bundler and test runner in one binary. | The Swift toolchain plus SwiftPM plus XCTest, as one command (`bun`). |
| **`Bun.serve`** | Bun's built-in HTTP server. You give it a table of URL patterns and handler functions. | A dictionary of routes to `async` closures returning a response. |
| **SQLite** (`bun:sqlite`) | The same embedded database engine iOS ships. All data lives in one file, `pubdb.sqlite`. | Exactly what sits under Core Data and SwiftData. |
| **React** | The web UI library for the existing web client. It lives in the same repo and is served by the same process. It is *not* part of the API. | SwiftUI, for the browser. |
| **WorkOS AuthKit** | A hosted sign-in service (Google, email codes). The backend uses it for accounts. | Like Sign in with Apple, but a third-party service that also does email and Google. |
| **`package.json`** | Dependencies and named scripts (`bun dev`, `bun run scrape`, …). | `Package.swift` combined with Xcode schemes. |
| **`bun test`** | Unit tests, all offline. | `xcodebuild test`. |

Some vocabulary you will see in the code:

- **Route / endpoint**: a URL path plus HTTP method, such as `GET /api/v1/pubs`.
- **Handler**: the function that runs for a route. It reads the request and returns a
  `Response` (status code, headers, body).
- **Query string**: the `?bbox=…&openNow=1` part of a URL. These are the parameters for
  `GET` requests.
- **JSON body**: the payload sent with a `POST`, for example `{"field":"guinness_price","value":"620"}`.
- **Session cookie**: how the server remembers a signed-in browser. It sets a cookie
  (`pubdb_session`) after sign-in, and the browser sends it back on every request.
- **Status codes** used here: `200` OK, `201` created, `304` not modified, `400` bad
  input, `401` not signed in, `403` not allowed, `404` not found, `409` duplicate,
  `429` too many requests, `500` server error.

## Shape of the program (v1 branch)

The whole backend is **one process** with four groups of routes:

```
                       ┌────────────────────────── one Bun process ──────────────────────────┐
 iOS / browser ──HTTP──▶ src/index.ts   (Bun.serve route table)                              │
                       │   │                                                                  │
                       │   ├── /api/v1/*  → src/api/routes.ts   public reads, signed-in writes │ ← the iOS app
                       │   │                   │   (+ rate-limit.ts)                          │
                       │   │                   ├─ src/db/*          SQL, builds Pub objects   │
                       │   │                   └─ src/lib/v1/present.ts  → the v1 JSON shapes │
                       │   │                                                                  │
                       │   ├── /auth/*    → src/api/auth.ts     WorkOS sign-in (browser flow)  │
                       │   ├── /admin/*   → src/api/admin.ts    operator tools, admins only    │
                       │   └── /*         → the React web app                                 │
                       │                                                                      │
                       │                       pubdb.sqlite (one file on disk)                │
                       └──────────────────────────────────────────────────────────────────────┘
```

A read request goes through these steps:

1. `src/index.ts` matches the URL against the route table.
2. The handler in `src/api/routes.ts` reads the query string. That includes **`at`**,
   the client's clock, which the server uses to decide what "now" and "tonight" mean.
3. It calls the database layer (`src/db/`). That code runs SQL **synchronously** (SQLite
   is local and fast) and builds an internal `Pub` by overlaying user contributions on
   the scraped data (see doc 2).
4. `src/lib/v1/present.ts` turns that into the public JSON. This is where the
   server works out open or closed, "Closes 01:00", "£6.20", "a month ago", the weekly
   table and so on. **The client receives answers, not raw data to interpret.**
5. The handler returns it as JSON.

Errors have one shape everywhere:
`{"error": {"code": "not_found", "message": "Unknown pub: …"}}`, with an extra `field` key when one input was at fault. Doc 3
has the list of codes.

**Unknown URLs return the web app's HTML, not a 404.** The last route, `/*`, sends
the web app's page for any path nothing else matched. A typo in an API path therefore
comes back as `200 text/html`. Check `Content-Type` in the networking layer (doc 4).

## Where it runs

```
 iPhone / browser
      │  HTTPS
      ▼
 pubdb.outerlimits.wtf
      │
 Cloudflare edge   (TLS and DDoS protection; no login wall any more)
      │
      │  Cloudflare Tunnel (the Pi dials *out*; no ports open at home)
      ▼
 Raspberry Pi 5 "mrsnuffles"
      └── bun src/index.ts  on 127.0.0.1:3000  (systemd service, restarts on failure)
            └── pubdb.sqlite   ← the live data, backed up daily to Nextcloud
```

**Security today**, according to the v1 branch's `deploy/RUNBOOK.md` (Cloudflare Access
was removed on 2026-08-26) and confirmed against production:

- **Reads (`GET /api/v1/*`) are public.** No login, no key.
- **Writes (`POST`, `PATCH`, `DELETE`) need a signed-in session** (WorkOS, cookie-based).
  If WorkOS is not configured, as on a developer laptop, writes are open.
- **`/admin/*`** is limited to accounts on an admin list, or to a secret token.
- **Rate limiting** is per client, kept in memory: 300 reads and 30 writes a minute.

It is still one Pi on a home connection. That is fine for friends, but payload size
and request count still matter (doc 4).

Deploying means copying files to the Pi and restarting the service. It is the backend
author's job and does not go through GitHub, which is why production can be ahead of
`main`.

## How data gets in

There are two separate flows, and only one of them involves a client.

### A. Offline pipelines (command-line scripts the author runs; no client involved)

On the v1 branch these live in `src/cli/`. They fill and enrich the `pubs` table and add
contributions in bulk.

| Script | What it does |
|---|---|
| `scrape` | Pulls pubs and bars from **OpenStreetMap** (via the Overpass API) for a region. It then enriches them with **food-hygiene ratings** (FSA), **heritage listings** (Wikidata), **photos** (Wikimedia Commons, or the pub website's `og:image`) and **former names** (OSM edit history). Scrapes are *additive*: they never wipe what users added. |
| `hellcat` | Imports years of hand-kept notes (Guinness prices with dates, venue scores, garden times). |
| `website-hours`, `website-llm`, `pub-times`, `serp-hours`, `hours-hunt` | Different ways of finding **opening hours**: structured data on pub websites, an LLM reading pub websites, pasted LLM write-ups, search results. |
| `gaps`, `osm-suggestions` | Reports: what is missing, and where PubDB knows better than OSM. |

When an importer cannot tell which pub a name refers to (there are many Red Lions), it
parks the item in a **review queue** that an admin settles under `/admin/import`. The
iOS app ignores all of this.

The data covers **London only**, about 5,300 pubs and bars.

### B. Live user contributions (later for iOS; not in the MVP)

A signed-in drinker can:

- **report a fact**: a Guinness price, when last orders was, when they were turned
  out, a feature, a correction
- **leave a review**: rated 1–10 on v1
- **delete a contribution or review**, which is how corrections are made
- **star pubs** for a personal "hit list" (the watchlist)

Each is one small HTTP request, documented in doc 3. The MVP does not do any of them.
