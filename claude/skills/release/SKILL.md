---
name: release
description: Run the dev→main release + tag workflow for a repo that follows the squash-merge / tag-on-deploy-branch model. Use when the user wants to cut a release, bump the version, ship dev to main, tag a version, or says "release this" / "make a release" / "tag the release". Drives the repo's npm run release / release:tag scripts (if present) and the surrounding git + gh steps.
---

# Release workflow (integration → deploy → tag → reset)

A release promotes the integration branch to the deploy branch, then tags the
commit that actually shipped. **Read `release.config.json` at the repo root first**
— it defines the real values. If it is missing, fall back to `main` (deploy) and
`dev` (integration) and confirm with the user.

Config fields you rely on: `appName`, `deployBranch`, `integrationBranch`,
`packages` (first entry is the version source), `lockfile`, `buildCommand`,
`releaseNotes`, `manualNotesFiles`, `tagMessage`.

## Two-phase invocation (this is normally a staged, human-in-the-loop release)
The user opens and reviews the release PR themselves; the skill is invoked at two
separate points, not as one automated run. Route by the user's phrasing, and if it
is ambiguous, disambiguate by the current branch.

- **Part 1 — the release commit.** Triggers: "release commit", "do part 1", "bump
  the version", "/release commit", or `/release` while on the **integration branch**.
  Do **only Step 1** below (version bump + `chore(release)` commit on the integration
  branch). Then STOP. Do **not** open or merge a PR and do **not** tag — the user
  reviews/merges their PR next. End by reminding them: after the PR is squash-merged,
  come back with "part 2".
- **Part 2 — tag + sync.** Triggers: "part 2", "tag the release", "tag and sync
  dev", "finish the release", "/release tag", or `/release` while on the **deploy
  branch**. Assume the PR is already squash-merged. Do **Steps 3 and 4** below
  (checkout/pull the deploy branch, tag, then the guarded reset). Skip Step 2 — the
  user handled the PR.

If the user just says "/release" with no qualifier: check the current branch —
integration branch ⇒ Part 1, deploy branch ⇒ Part 2 — and state which part you are
doing before acting. Step 2 (open + squash-merge the PR) is the user's in staged
mode; only do it if they explicitly ask you to (or in full mode below).

## Full release (end-to-end, only when explicitly asked)
Triggers: "full release", "do the whole release", "run the entire release process",
"release everything from here" — used when the user is satisfied with the integration
branch and wants you to carry it all the way to a tagged deploy. Unlike the staged
mode, this mode **does** own the PR and merge, and **does** push (creating, merging,
and tagging inherently require it; still use `--force-with-lease` for the reset). Run
in this order and finish on the deploy branch:

1. Preconditions: on the integration branch, clean tree, `git fetch`. Determine the
   version/level from the commits since the last tag (`--dry-run` previews it).
2. Push the integration branch, then open the PR:
   `gh pr create --base <deployBranch> --head <integrationBranch>`. **Title = a
   Conventional Commit line** summarizing the release (this becomes the squash subject
   in Step 5); **body = what changed, why, and any reviewer notes.**
3. Review the PR diff (optionally via the `/code-review` skill). Fix any genuine bugs
   or improvements with normal commits on the integration branch — they update the
   PR. For non-essential/optional changes, ask the user before making them.
4. Make the release commit — **Step 1** below — on the integration branch, then push
   so the open PR includes it.
5. Squash-merge: `gh pr merge --squash`. The squash subject **must be a Conventional
   Commit line and must keep the PR number**, e.g. `feat: <summary> (#<N>)`. If you
   override the subject, append ` (#<N>)` yourself — gh does not add it for a custom
   subject.
6. Tag — **Step 3** below — on the deploy branch (checkout, pull, `git tag -a`, push
   the tag).
7. Sync — **Step 4** below — reset the integration branch to the deploy branch and
   `--force-with-lease` push it.
8. Finish on the deploy branch (`git checkout <deployBranch>`) and report the tag and
   the merged PR URL.

Ordering note: in full mode the PR is opened *before* the release commit, so the
release commit lands as an update to the open PR and is captured by the squash — do
not open a second PR for it.

## Scripts vs. doing it by hand
The repo's `npm run release` / `npm run release:tag` scripts are **interactive**
(readline prompts; they refuse a non-TTY). You cannot feed them answers. So:
- When the **user is at their terminal**, tell them which script to run and when.
- When acting **autonomously**, replicate the script's effect with the git
  commands below (bump versions, commit, tag) — do not try to pipe into the scripts.
- If the repo has **no** release scripts/config, drive the whole flow by hand with
  git/gh, or offer to add the portable scripts (`scripts/release*.mjs` +
  `release.config.json`) copied from a repo that already has them.

## Preconditions
- `git status` clean; on the integration branch; `git fetch` done.
- Last tag: `git tag --list 'v[0-9]*' --sort=-version:refname` → `git log <lasttag>..HEAD --format='%s'`.
- Level from Conventional Commits: `!`/`BREAKING CHANGE:` → major; else `feat:` → minor; else patch.
- `npm run release -- --dry-run` previews the suggestion and changelog without changing anything.

## 1. Version bump commit (on the integration branch)
Preferred: user runs **`npm run release`** (bumps every `packages` entry + lockfile,
runs `buildCommand` as a gate, prepends an auto-generated section to the
`releaseNotes` file, and commits `chore(release): vX.Y.Z`; no tag, no push).
By hand: bump `version` in every `packages` path + the lockfile (`version`,
`packages[""]`, each `packages/<name>`); update `manualNotesFiles`; run `buildCommand`;
`git commit -m "chore(release): vX.Y.Z"`. **Never tag here.**

**Then rewrite the notes into human-readable form and fold it into the SAME
commit.** The script only drops raw Conventional-Commit subjects at the top of the
`releaseNotes` file (see `release.config.json`). After the `chore(release)` commit
exists, edit just that newest top section — the one under the `# <appName> X.Y.Z`
heading you (or the script) just added — into readable release notes: group related
changes, write user-facing prose, drop noise like `chore`/`release`/merge commits.
Keep the `# <appName> X.Y.Z` heading (packaging asserts the file's first line), keep
older sections untouched, then `git commit --amend --no-edit` so the message stays
`chore(release): vX.Y.Z`. If the user is running the script in their own terminal,
do this amend step for them afterward (or hand them the rewritten section).

## 2. Open the PR and SQUASH-merge
- Push the integration branch only if the user asks.
- `gh pr create --base <deployBranch> --head <integrationBranch> ...` then
  `gh pr merge --squash`. The squash is the deploy trigger and rewrites the
  integration commit into a new commit on the deploy branch with a new SHA —
  which is why tagging is a separate step.

## 3. Tag on the deploy branch's squash commit
- `git checkout <deployBranch> && git pull`.
- Preferred: user runs **`npm run release:tag`** (refuses off the deploy branch,
  refuses if the tag exists, tags from the package version, offers to push, then
  offers the integration-branch reset).
- By hand: `git tag -a vX.Y.Z -m "<tagMessage>"`; push only when asked
  (`git push origin vX.Y.Z`).

## 4. Reset the integration branch to the deploy branch
Only after the tag lands, and only when **`git diff <deployBranch> <integrationBranch>`**
is empty and the tree is clean:
`git checkout <integrationBranch> && git reset --hard <deployBranch> && git push --force-with-lease origin <integrationBranch>`.
If that diff is NOT empty, stop — there is unmerged work; reconcile manually.

## Hard rules (do not skip)
- **Tag on the deploy branch, never on the integration release commit.** After a
  squash the integration commit is not an ancestor of the deploy branch.
- **Reset integration to deploy; never merge deploy back into integration.** Reset
  is lossless only when the branches' content is identical — verify with `git diff` first.
- **CI runs only on the deploy branch.** Never add CI for integration/feature branches.
- **Push / force-push only when the user asks.** Force-pushing the integration
  branch after a release is expected; always `--force-with-lease`.
- A release is complete only when the shipped commit on the deploy branch carries
  the matching annotated `vX.Y.Z` tag.

## Feature branches (optional)
Small changes go straight to the integration branch. Cut a `feat/*` (or
`fix/*`, `refactor/*`) branch from it only for large/complex changes that warrant a
separate review before landing; merge back, then release. Never bump the version or
tag during feature work.
