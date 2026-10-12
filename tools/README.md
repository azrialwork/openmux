<!--
  tools/README.md -- Why tools/ is (almost) empty.

  Explains the fetch-at-build-time decision for the transplant toolchain and
  how to bump the pinned commit. One topic: toolchain sourcing.
-->

# tools/

This directory is intentionally almost empty. Two build inputs are sourced
outside the repo:

1. **Transplant toolchain** -- fetched at build time by `build.yml` via a
   sparse checkout of `tools/transplant` from `Hope2333/opencode-termux` at
   the pinned commit in `TRANSPLANT_REF`. The pin is explicit and auditable
   in one place; bump it deliberately after checking their changelog.

2. **Bionic libopentui.so** -- vendored at `vendor/libopentui-bionic.so`
   (see `vendor/README.md` for provenance). It cannot be built on x86 CI,
   so a prebuilt is committed. `build.yml` stages it where `transplant.py`
   expects it (`artifacts/transplant/opentui-bionic/libopentui.so`).

Why not vendor the toolchain too:

- The repo stays tiny (the toolchain plus its history is far larger than
  everything else here).
- Upstream fixes are picked up by bumping one SHA, not by re-vendoring.

How to bump `TRANSPLANT_REF`:

1. Check what changed upstream (`Hope2333/opencode-termux`, branch
   `native-android`), especially `tools/transplant/config/bun-bind.json`
   (the Android Bun base) and anything touching the `.bun` section format.
2. Run `build.yml` manually with the new SHA in a test branch first.
3. Only then update the pin on `main`.

License note: the toolchain and the vendored `.so` are MIT-licensed
(Hope2333/opencode-termux); attribution is in README.md and build.yml
comments.
