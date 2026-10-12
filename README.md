<!--
  README.md -- Project overview for opencode-termux.

  What this repo is, how the native Bionic build works, repo layout, setup
  steps, usage, and limitations. One topic: this repo's workflow.
-->

# opencode-termux

OpenCode running **natively** on Termux (Android aarch64) -- a Bionic-linked
binary with zero glibc, no proot, no root. Built by GitHub Actions with the
transplant pipeline and published to GitHub Releases. Install with one line:

```sh
curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB_USER/opencode-termux/main/install.sh | bash
```

After install, set a provider key and run:

```sh
export ANTHROPIC_API_KEY="sk-..."  # or OPENAI_API_KEY
opencode
```

## How it works

OpenCode ships as a `bun build --compile` standalone binary: a Bun runtime
with the app's JS module graph appended. Bun publishes official Android
(Bionic) builds, but they are interpreter-only -- the standalone entry code
is added at compile time, which cannot run on Android.

`build.yml` fixes this with the **transplant pipeline** (from
[Hope2333/opencode-termux](https://github.com/Hope2333/opencode-termux), MIT):

1. `npm pack opencode-linux-arm64@<ver>` -- upstream tarball
2. Download the official Android Bun pinned in `config/bun-bind.json`
3. `transplant.py all --no-execve` -- extract the module graph, graft it onto
   the Android Bun, **revive** the standalone entry (patch `BUN_COMPILED.size`
   ASLR-safely), and swap in a Bionic `libopentui.so` for full TUI rendering
4. Sanity-check the ELF on x86 (aarch64 arch, Bionic `libc.so`, no
   `libc.so.6`), package it as `opencode-android-aarch64.tar.gz`, and create
   the GitHub Release

`watch-upstream.yml` polls upstream weekly and triggers a build for new
versions automatically.

## Layout

```
opencode-termux/
  install.sh                 # curl|bash entrypoint (POSIX sh, checksum-verified)
  .github/workflows/
    build.yml                # transplant -> package -> GitHub Release
    watch-upstream.yml       # weekly poll -> trigger build on new upstream
  tools/
    README.md                # the transplant toolchain is fetched at build time (pinned)
```

The transplant toolchain itself is **not vendored** -- `build.yml` sparse-
checks out `tools/transplant` from Hope2333/opencode-termux at the pinned
commit in `TRANSPLANT_REF`, so the repo stays tiny and the pin is auditable.
Bump it deliberately after checking their changelog.

## Setup (first time)

1. Create a **private** GitHub repo named `opencode-termux` and push this.
2. In `install.sh`, set `REPO="your-user/opencode-termux"`.
3. Actions tab -> `Build native OpenCode` -> Run workflow (version `latest`).
4. Wait a few minutes, check the new Release, then on your phone run the
   one-liner above.

No secrets needed: everything runs on the free tier with `GITHUB_TOKEN`.

## Requirements (phone side)

- Termux (F-Droid or GitHub build), Android 9+ (API 28+), aarch64
- ~200 MB free storage; `curl`, `tar` (preinstalled in Termux)

## Limitations (honest)

- Cold start is ~2 s (module graph parsing).
- `@parcel/watcher`'s native binding is x86_64-only, so file watching is
  degraded (polling fallback).
- `bun upgrade` is disabled (no Android release channel upstream).
- Only aarch64 is built.

## Credits

- [OpenCode](https://opencode.ai) by Anomaly -- the agent itself
- [Bun](https://bun.sh) by Oven -- the runtime (official Android builds)
- [Hope2333/opencode-termux](https://github.com/Hope2333/opencode-termux)
  (MIT) -- the transplant pipeline this workflow reuses
- [wallentx/claude-code-termux](https://github.com/wallentx/claude-code-termux)
  -- the repo/release/installer shape this project follows

## License

MIT. See LICENSE.
