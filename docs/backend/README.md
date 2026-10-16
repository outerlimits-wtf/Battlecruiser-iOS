# PubDB backend: a guide for the iOS side

These documents explain the PubDB backend to someone who knows iOS well and
backend/TypeScript not at all. They are written from the code and from the live
server, not from intentions. Where those disagree, the docs say so.

| # | Document | What you get from it |
|---|---|---|
| 1 | [The big picture](01-big-picture.md) | What the backend is, the tools it uses (with iOS analogies), where it runs, and how data gets into it. |
| 2 | [The data model](02-data-model.md) | The tables, how a pub is assembled from scraped data plus user contributions, and the domain rules (Guinness price, last orders, "tonight"). |
| 3 | [API v1 reference](03-api-reference.md) | The endpoints the app uses, as production serves them today, with example JSON, Swift `Codable` sketches, and where the spec and the server differ. |
| 4 | [Serving the iOS client](04-ios-integration.md) | How the MVP talks to the backend: networking, caching, what the app does and does not compute, and the path to sign-in later. |
| 5 | [Decisions and open questions](05-decisions.md) | What has been decided for the MVP, and what is still open. |

## Which backend? Read this first

There are **two versions** of the backend, and the difference matters:

| | `main` on GitHub (and your local `pubdb` checkout) | Branch `chore/latest-close-and-prettier` |
|---|---|---|
| Last commit | 31 Jul 2026 (`593e960`) | 2 Sep 2026 (`74a21cc`), **81 commits ahead** |
| API | Unversioned `/api/...` | **`/api/v1/...`**, designed for a native client |
| Who computes "open now", labels, prices | The client | **The server** |
| Accounts | None | WorkOS sign-in, for writes only |
| Running in production? | No | **Yes**, checked against `https://pubdb.outerlimits.wtf` on 2026-10-16 |

**The iOS app targets v1.** It is what production runs. It also comes with a written
contract: `spec/pubdb-api-v1.md` on that branch, 861 lines, which names an iOS client
as its intended audience. Unchanged from the first version of these docs:

- The concepts in docs 1 and 2: the contributions model, the "night the session
  started" rule, the Guinness price rule. The server still works that way inside.
  v1 just hands you the results instead of the raw data.

What changed:

- Doc 3 is rewritten for v1.
- Doc 4's blockers have mostly gone away: v1 reads are public, and it computes open
  state, labels and distances on the server.

To read the v1 code locally without disturbing your `pubdb` checkout:

```bash
gh repo clone outerlimits-wtf/pubdb ~/Documents/Dev/pubdb-v1 -- --branch chore/latest-close-and-prettier
```

Files that matter most on that branch:

- `spec/pubdb-api-v1.md`: the API contract. Read this alongside doc 3. A test
  (`src/api/contract.test.ts`) checks the server against the JSON examples in it.
- `src/api/routes.ts`: the v1 endpoints
- `src/lib/v1/present.ts`: turns database rows into the v1 JSON shapes
- `src/api/auth.ts`: sign-in (WorkOS), and the rule that reads are public and writes
  need a session
- `src/db/`: the database layer, split into several files

Written 2026-10-16. The examples come from production on that date.
