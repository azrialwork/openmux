# Upstream baseline

- Upstream: `anomalyco/opencode` — https://github.com/anomalyco/opencode
  (formerly `sst/opencode`)
- Tracked line: v2.x.x only
- Pinned baseline: **v2.2.6**
- Baseline commit: `dc2ffcf8bf26f9e669b6aa22b95f50e12be15e06`
- Baseline verified: 2026-11-07 — highest v2 tag on GitHub, a GitHub
  release, and the latest `@opencode/cli` version on npm all agree.
- Machine-readable copy: `upstream.json` (the workflows read that file;
  keep this file in sync when the baseline moves)
- Local read-only reference snapshot (Boss's machine only, not part of
  this repository): `~/workspace/opencode-v2.2.6`

## Checking policy

- Upstream is checked for a newer v2.x.x **every 6 hours** by the
  `check-upstream` GitHub Actions workflow, and by a scheduled check
  on Boss's assistant.
- A check reports only. It never moves the baseline and never rebases
  patches by itself.
- Moving the baseline is a deliberate change: update `upstream.json`
  and this file in one commit, re-apply every patch in
  `patches/series` onto the new baseline, and let CI prove they
  still apply and build.
