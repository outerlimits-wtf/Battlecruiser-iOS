# Branching and release process (git-flow)

Battlecruiser uses classic git-flow. This document is the rule book; the CI workflows and
fastlane lanes (added in later steps) follow it.

## Branches

| Branch | Cut from | Merges into | Lifetime | Purpose |
| --- | --- | --- | --- | --- |
| `main` | n/a | n/a | permanent | Exactly what has been released. Every commit on `main` is a release and carries a `vX.Y.Z` tag. |
| `develop` | `main` | n/a | permanent | Integration branch. The next release in progress. Always builds and passes tests. |
| `feature/<name>` | `develop` | `develop` | short | One piece of work. |
| `release/X.Y.Z` | `develop` | `main` and `develop` | days | Stabilise a release: version bump, fixes, TestFlight builds. No new features. |
| `hotfix/X.Y.Z` | `main` | `main` and `develop` | hours | Urgent fix to the released version. |

Names are lowercase, hyphenated: `feature/pub-detail-hours`, `release/1.1.0`, `hotfix/1.0.1`.

## Rules

1. Nobody commits directly to `main` or `develop`. Everything arrives through a pull request.
2. Feature branches merge into `develop` by **squash merge**: one commit per feature, with a
   message that explains the work.
3. Release and hotfix branches merge into `main` by **merge commit** (no squash), so the
   release history is preserved. `main` is then merged back into `develop`.
4. A pull request needs the CI checks (build and test) green before it can merge.
5. Branches are deleted after merge.

## Versioning

- Semantic versioning, `MAJOR.MINOR.PATCH`, stored in the Xcode project as `MARKETING_VERSION`
  (currently `1.0.0`).
- `CURRENT_PROJECT_VERSION` (the build number) is bumped by the release lanes. It only has to
  increase; it is not the same thing as the release number.
- A release is tagged on `main` as `vX.Y.Z`.

## Day to day: a feature

```bash
git switch develop && git pull
git switch -c feature/my-thing
# work, commit, push
git push -u origin feature/my-thing
# open a PR into develop; squash merge when CI is green
```

## Cutting a release

1. Cut `release/X.Y.Z` from up-to-date `develop`.
2. On the release branch only: set `MARKETING_VERSION`, update release notes, fix bugs found
   in testing. Each push can produce a TestFlight build (once deploy lanes are enabled).
3. Open a PR `release/X.Y.Z` into `main`. When approved and green, merge with a merge commit.
4. Tag the merge commit on `main`: `vX.Y.Z`. Pushing the tag is what triggers the
   App Store / TestFlight release workflow (once enabled).
5. Open a PR from `main` back into `develop` so the release fixes are not lost. Merge it,
   then delete the release branch.

## Hotfix

1. Cut `hotfix/X.Y.Z` from `main` (the patch version is `X.Y.Z`, one above the broken release).
2. Fix, bump `MARKETING_VERSION`, open a PR into `main`, merge with a merge commit, tag `vX.Y.Z`.
3. Merge `main` back into `develop` (or into the open `release/*` branch if one exists, then
   it flows to `develop` with the release).

## GitHub settings to apply (by the repository owner)

These live in the repository settings, not in files:

- Default branch: `develop`.
- Branch protection on `main` and `develop`: require a pull request, require the CI status
  checks to pass, block force pushes and deletion.
- Allowed merge methods: squash and merge commit (turn off rebase merging). Use squash for
  `feature/*`, merge commit for `release/*` and `hotfix/*`.
- Automatically delete head branches after merge.
- Tag protection for `v*`.

## Who does what

Claude (and any other assistant) never creates branches, commits, tags or pushes in this
repository unless asked for that exact action; see `.claude/CLAUDE.md`. The git commands in
this document are for the maintainer to run.
