<!--
  tools/README.md -- Why tools/ is (almost) empty.

  Explains the fetch-at-build-time decision for the transplant toolchain and
  how to bump the pinned commit. One topic: toolchain sourcing.
-->

# tools/

This directory is intentionally almost empty. The transplant toolchain
(`transplant.py`, `revive_patch.py`, `swap_tui.py`, `build-libopentui.sh`,
`config/bun-bind.json`, ...) is **fetched at build time** by `build.yml`:

```yaml
env:
  TRANSPLANT_REPO: Hope2333/opencode-termux
  TRANSPLANT_REF: 736540a066a2ef2f6824064982509583b37eb2ab
```

via a sparse checkout of `tools/transplant` at that pinned commit.

Why not vendor it:

- The repo stays tiny (the toolchain plus its history is far larger than
  everything else here).
- The pin is explicit and auditable in one place (`build.yml`).
- Upstream fixes are picked up by bumping one SHA, not by re-vendoring.

How to bump `TRANSPLANT_REF`:

1. Check what changed upstream (`Hope2333/opencode-termux`, branch
   `native-android`), especially `tools/transplant/config/bun-bind.json`
   (the Android Bun base) and anything touching the `.bun` section format.
2. Run `build.yml` manually with the new SHA in a test branch first.
3. Only then update the pin on `main`.

License note: the toolchain is MIT-licensed (Hope2333/opencode-termux);
attribution is in README.md and build.yml comments.
