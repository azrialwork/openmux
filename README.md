# openmux

Delta-only repository on top of upstream OpenCode v2.

This repository is **not** a fork and does not contain a copy of the
OpenCode source tree. It contains only the delta that Boss wants to
carry on top of upstream:

- `patches/` — ordered patches against a pinned upstream baseline
- `upstream.json` — the pinned upstream baseline (machine-readable)
- `UPSTREAM.md` — the same baseline in human-readable form, plus the
  checking policy
- `scripts/` — helpers to check upstream and to apply the delta

## Upstream

- Repository: https://github.com/anomalyco/opencode
  (formerly `sst/opencode`)
- Tracked line: v2.x.x only
- Current baseline: **v2.2.6**
  (commit `dc2ffcf8bf26f9e669b6aa22b95f50e12be15e06`)
- Local read-only reference snapshot of that baseline:
  `../opencode-v2.2.6` (`~/workspace/opencode-v2.2.6`, read-only —
  never edit it)

## Checking policy

Upstream is checked for a newer v2.x.x release **every 6 hours**
(automated job: `openmux-check-upstream`).

A check never moves the baseline and never rebases patches on its
own. If a newer v2.x.x exists, it is reported to Boss; moving the
baseline and rebasing the patches in `patches/` happens only on
Boss's decision.

## Adding a patch

1. Work on a writable copy checked out at the baseline in
   `upstream.json` — never on the read-only snapshot.
2. Make one logical change per patch.
3. Export it as a patch file and add it to `patches/` with the next
   number, e.g. `patches/0001-short-description.patch`
   (`git format-patch` output is preferred).
4. Add the filename, in apply order, to `patches/series`.
5. Note the patch in `patches/README.md`: what it does and why.

## Applying the delta

```sh
scripts/apply-patches.sh <target-dir>
```

This clones upstream at the pinned baseline into `<target-dir>` and
applies every patch listed in `patches/series`, in order.

## CI/CD — all builds in GitHub Actions

No release build is ever produced on a local machine. Everything is
built by GitHub Actions from this repository, using the one build
entry point `scripts/build.sh` (pinned baseline → apply patches →
`bun install --frozen-lockfile` → build the CLI with Bun 1.4.4 →
smoke-test the binary with `--version` → tar.gz + sha256).

- **CI** (`.github/workflows/ci.yml`) — on every push to `main` and
  every pull request: validates `upstream.json`, checks every patch
  applies cleanly onto the pinned baseline, then builds linux-x64
  and uploads it as a workflow artifact.
- **Upstream check** (`.github/workflows/check-upstream.yml`) —
  every 6 hours: if a newer OpenCode v2.x.x exists, it opens one
  GitHub issue for that version. It never moves the baseline.
- **Release** (`.github/workflows/release.yml`) — on a `v*` tag of
  this repository (or a manual dispatch with a version): builds
  linux-x64 and linux-arm64, then publishes a GitHub Release with
  both archives and a combined `SHA256SUMS`. Release notes name the
  exact upstream baseline the release was built on.

openmux versions are its own (`v0.1.0`, `v0.2.0`, ...) and are
independent of the upstream version named in the release title.
