# openmux

Delta-only repository on top of upstream OpenCode v2.

This repository is **not** a fork and does not contain a copy of the
OpenCode source tree. It contains only the delta carried on top of
upstream:

- `patches/` — the delta: ordered patches against a pinned upstream
  baseline, grouped by decision (see `patches/README.md`)
- `upstream.json` — the pinned upstream baseline (machine-readable)
- `UPSTREAM.md` — the same baseline in human-readable form, plus the
  checking policy
- `scripts/` — the entry points: apply the delta, build, check
  upstream (shared helpers in `scripts/lib/`)
- `install.sh` — installs a release build (below)
- `.github/` — CI, release and upstream-check workflows; setup
  shared by the workflows lives in `.github/actions/`
- `AGENTS.md` — the working guide and invariants for contributors
  and coding agents

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/azrialwork/openmux/main/install.sh | bash
```

The installer detects the platform (Linux x86_64, Linux aarch64, or
Termux on Android aarch64), downloads that target's archive from the
latest release, verifies it against the release's `SHA256SUMS`, and
installs the `opencode` binary into `$PREFIX/bin` (Termux) or
`~/.local/bin`. Pin a version or change the destination with
`OPENMUX_VERSION=v0.9.0` / `OPENMUX_INSTALL_DIR=/some/dir`.

## The delta

On top of upstream v2.2.6, the series in `patches/series`:

| Patches | Decision |
| --- | --- |
| 0001–0004 (`01-cli-tui-only/`) | CLI and TUI only — every other environment (web GUI, desktop, docs site, SDK, hosted services) is deleted, references included |
| 0005 (`02-providers-and-models/`) | Only the OpenCode Free Models (47) ship built in; everything else is a user-defined custom provider |
| 0006, 0009 (`03-termux-bionic/`) | A native Android (Termux/Bionic) build target, TUI included; recursive directory watching works there too — the real @parcel/watcher android build is embedded |
| 0007 (`04-no-self-update/`) | The self-update feature is removed completely — no `upgrade` command, no background update checks, no update UI or config settings |
| 0008 (`05-deletion-cleanup/`) | Completes the earlier deletions: leftover pairing/acp tests and the orphaned Claude Agent SDK dependency are removed |
| 0010 (`06-dedupe-slash-commands/`) | Slash commands are deduplicated: each command appears once in the slash menu, under its original name — aliases stay valid input but no longer get rows of their own |

Full per-patch notes, including why each patch exists:
`patches/README.md`.

## Upstream

- Repository: https://github.com/anomalyco/opencode
  (formerly `sst/opencode`)
- Tracked line: v2.x.x only
- Current baseline: **v2.2.6**
  (commit `dc2ffcf8bf26f9e669b6aa22b95f50e12be15e06`)

## Checking policy

Upstream is checked for a newer v2.x.x release **every 6 hours**
(GitHub workflow plus a maintainer-side job).

A check never moves the baseline and never rebases patches on its
own. If a newer v2.x.x exists, it is reported; moving the baseline
and rebasing the patches in `patches/` happens only on the
maintainer's decision.

## Adding a patch

1. Work on a writable copy checked out at the baseline in
   `upstream.json` — never on a read-only snapshot.
2. Make one logical change per patch decision.
3. Export it (`git format-patch` output preferred) into the
   decision's directory under `patches/` — a new directory
   `patches/NN-short-name/` for a new decision — named with the
   next free number. Numbering is dense and global, in apply
   order, across all directories.
4. Add the path, in apply order, to `patches/series`.
5. Add a row to `patches/README.md`: what the patch does and why.
   (Release notes are generated from that table.)

The full rules and invariants are in `AGENTS.md`.

## Applying the delta

```sh
scripts/apply-patches.sh <target-dir>
```

This clones upstream at the pinned baseline into `<target-dir>` and
applies every patch listed in `patches/series`, in order. Set
`OPENMUX_UPSTREAM_URL` to clone from a local mirror instead.

## CI/CD — all builds in GitHub Actions

No release build is ever produced on a local machine. Everything is
built by GitHub Actions from this repository, using the one build
entry point `scripts/build.sh` (pinned baseline → apply patches →
`bun install --frozen-lockfile` → build the CLI with Bun 1.4.4 →
smoke-test → tar.gz + sha256).

- **CI** (`.github/workflows/ci.yml`) — on every push to `main` and
  every pull request: validates `upstream.json` and every script,
  applies the whole series onto the pinned baseline via
  `scripts/apply-patches.sh`, then builds linux-x64 and
  linux-arm64-android and uploads them as workflow artifacts.
- **Upstream check** (`.github/workflows/check-upstream.yml`) —
  every 6 hours: if a newer OpenCode v2.x.x exists, it opens one
  GitHub issue for that version. It never moves the baseline.
- **Release** (`.github/workflows/release.yml`) — on a `v*` tag of
  this repository (or a manual dispatch with a version): builds
  linux-x64, linux-arm64 and linux-arm64-android, then publishes a
  GitHub Release with all archives and a combined `SHA256SUMS`.
  Release notes are generated from `patches/series` and
  `patches/README.md`, and name the exact upstream baseline the
  release was built on.

openmux versions are its own (`v0.1.0`, `v0.2.0`, ...) and are
independent of the upstream version the binaries report
(`opencode v2.2.6` — the baseline version).
