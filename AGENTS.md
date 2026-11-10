# AGENTS.md — working in the openmux repository

Guidance for any coding agent (or human) working in this repo. Read
this first; it states what the repository is, the invariants that
must not be broken, and how the routine tasks are done.

## What this repository is

openmux is a **delta-only** repository on top of upstream OpenCode
v2 (`anomalyco/opencode`). It is **not a fork** and it contains **no
copy of the upstream source tree**. The entire product is:

- `upstream.json` — the pinned upstream baseline (tag + commit).
- `patches/` — the delta: an ordered series of patch files against
  that baseline, grouped by decision.
- `scripts/` — the only entry points for applying the delta,
  building, and checking upstream.
- `install.sh` — the end-user installer (downloads a release build).
- `.github/` — CI, the upstream check, and the release workflow,
  with shared setup in `.github/actions/`.

If you find yourself wanting to edit OpenCode source code here:
stop. Source changes are made in a separate working copy checked
out at the baseline, then exported as a patch and added under
`patches/` (see "Adding a patch").

## The delta, in one paragraph

On top of upstream v2.2.6 the series currently: (0001–0004) deletes
every environment except the CLI and the TUI — web GUI, desktop,
docs site, SDK, hosted services — including all references to them;
(0005) removes every built-in provider/model except the 47 free
OpenCode models, keeping user-defined custom providers; (0006) adds
a native Android (Termux/Bionic) build target whose TUI is bridged
from the musl OpenTUI library via a small Bionic compat shim;
(0007) removes the self-update feature completely — the `upgrade`
command, the background update checks, the TUI update dialog and
banner, the installation events, and the `update`/`autoupdate`
config settings; (0008) completes the earlier deletions — leftover
pairing/acp tests and the orphaned Claude Agent SDK dependency
removed; (0009) makes recursive directory watching work on
Android, replacing patch 0006's parcel-watcher stub with the
embedded @parcel/watcher android build.
Per-patch detail, including the reasoning, is in `patches/README.md`.
Patches 0006–0009 of the old numbering (system prompt, tool
descriptions, agent prompts, delegation enforcement) were
**withdrawn by the maintainer on 2026-11-09** and are not in the
series; do not re-add them without the maintainer's explicit
decision. Their content survives in git
history.

## Layout

```
upstream.json            baseline pin (machine-readable)
UPSTREAM.md              baseline pin (human) + checking policy
install.sh               curl | bash installer for end users
AGENTS.md                this file
README.md                project overview for humans
patches/
  series                 apply order — the single source of truth
  README.md              per-patch what/why (release notes read it)
  01-cli-tui-only/       patches 0001-0004
  02-providers-and-models/  patch 0005
  03-termux-bionic/      patches 0006, 0009
  04-no-self-update/     patch 0007
  05-deletion-cleanup/   patch 0008
scripts/
  apply-patches.sh       clone baseline + apply the series
  build.sh               the one build entry point (all targets)
  check-upstream.sh      report newer upstream v2.x.x, if any
  lib/common.sh          shared helpers (sourced, not executed)
.github/
  actions/setup-runtime/ Node + Bun versions for every build job
  actions/setup-android/ patchelf + NDK + GH_TOKEN for android jobs
  workflows/ci.yml       validate + build linux-x64 + linux-arm64-android
  workflows/release.yml  on v* tags: build 3 targets, publish release
  workflows/check-upstream.yml  every 6h: open an issue per new version
```

## Invariants — do not break these

1. **The baseline never moves on its own.** `upstream.json` /
   `UPSTREAM.md` change only on the maintainer's explicit decision.
   A failing patch is fixed by fixing the patch, never by moving
   the pin.
2. **Patch files are byte-exact.** `.gitattributes` marks
   `patches/**/*.patch` as `-text`; never let an editor or a git
   setting normalize line endings inside them, and never regenerate
   a patch to "tidy" it. A moved or renamed patch must keep its
   exact blob hash.
3. **One apply implementation.** Everything that needs the patched
   tree goes through `scripts/apply-patches.sh` (the series is read
   there, in order). Do not copy the apply loop into workflows or
   other scripts.
4. **One build entry point.** Builds go through `scripts/build.sh`.
   Release builds run in GitHub Actions only — never ship a locally
   built binary as a release.
5. **Versions are independent.** Binaries report the *upstream*
   version (`opencode v2.2.6` — `build.sh` stamps `OPENCODE_VERSION`
   from the baseline tag). openmux's own versions (`v0.9.0`, ...)
   exist only as release tags of this repo.
6. **Release notes are generated** by `release.yml` from
   `patches/series` + the "What it does" column of
   `patches/README.md`, matched by patch file name. Keep that
   table's file names exact and current in the same change that
   adds, renames, or removes a patch.
7. **Second-party materials only** for the android target: OpenCode
   upstream, official Bun, the Termux project, the Android NDK.
   No third-party forks, patches, or prebuilt binaries.
8. **Android jobs run on the x64 runner** (`ubuntu-24.04`), not the
   arm image: the NDK's host tools are x86_64 binaries and the arm
   image ships no NDK. The android build is a pure cross-compile.

## Routine tasks

### Adding a patch

1. Work in a writable copy checked out at the baseline commit —
   never in this repo and never in a read-only snapshot.
2. One logical change per patch decision. Commit it there with a
   conventional-commit message.
3. Export with `git format-patch` against the baseline-side history
   so the message and authorship survive.
4. Place the file in the decision's directory under `patches/`
   (create `patches/NN-short-name/` for a new decision), named with
   the next free global number — numbering is dense across all
   directories, in apply order. Mind the 100 MB per-file limit;
   split inside the directory if needed.
5. Append the path (relative to `patches/`) to `patches/series`.
6. Add a row to the table in `patches/README.md`: exact file name,
   what it does, why it exists.
7. Let CI prove it: the validate job applies the whole series onto
   the pinned baseline; the build jobs build linux-x64 and
   linux-arm64-android.

### Verifying the delta locally

`scripts/apply-patches.sh <dir>` clones upstream at the baseline
and applies the series (set `OPENMUX_UPSTREAM_URL` to a local path
to clone from a mirror instead). Applying the full series must
reproduce exactly the tree of the working copy the patches were
exported from — that round-trip equality is the correctness test
for any patch reorganization.

### Releasing

Releases are the maintainer's decision. Mechanically: push an
annotated `vX.Y.Z` tag of this repo; `release.yml` builds
linux-x64, linux-arm64 and linux-arm64-android, generates notes,
and publishes the release with all archives + `SHA256SUMS`. After
publishing, download the assets, verify `SHA256SUMS`, run the x64
binary, and — for the android asset — run the shipped binary on a
real device before calling the release done.

### Checking upstream

`scripts/check-upstream.sh` prints `UP_TO_DATE` or
`NEW_VERSION_AVAILABLE ...`. The scheduled workflow opens one issue
per new version. Reporting is all it ever does (invariant 1).

## Working rules for agents

- Chat with the maintainer in Indonesian; write all repository
  content in English.
- Commit messages: conventional commits, e.g.
  `feat(patches): add patch 0007 — <summary>`,
  `fix(ci): <summary>`, `refactor(scripts): <summary>`.
- Do not push, tag, or release without the maintainer's explicit
  go-ahead for that exact action.
- When reorganizing (renaming/moving patches, restructuring
  scripts), prove afterwards that (a) every patch blob hash is
  unchanged and (b) the round-trip tree is identical to before.
- Keep scripts POSIX-lean bash with `set -euo pipefail`; shared
  logic belongs in `scripts/lib/common.sh`, workflow setup shared
  by CI and release belongs in `.github/actions/`.
