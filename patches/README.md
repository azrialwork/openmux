# Patches

This directory holds the entire delta that `openmux` carries on top
of the upstream baseline pinned in `../upstream.json`.

## Rules

- One logical change per patch decision. A decision lives in its own
  directory, `NN-short-name/`, in decision order. A decision that
  produces several patch files (only because of the size limit
  below) keeps them together in its directory.
- Files are named `NNNN-short-description.patch` and numbered
  densely and globally — `0001`, `0002`, ... in apply order across
  all directories, with no gaps. A new patch takes the next free
  number. (Numbering was made dense in the 2026-11-10 restructure;
  in the old flat layout the Termux patch was numbered 0010 and is
  now 0006.)
- No single patch file may exceed GitHub's 100 MB per-file limit;
  split an oversized change into several files inside its directory.
- `series` lists the patch paths (relative to this directory) in
  apply order, one per line. Lines starting with `#` and blank
  lines are ignored. The series is the single source of truth for
  apply order — directory and file names only mirror it.
- Every patch is listed in the table below with what it does and
  why. The release workflow reads the "What it does" column from
  this table (matched by file name) to build the release notes, so
  keep the file names in the table exact.
- Preferred format: `git format-patch` output against the pinned
  baseline commit, so authorship and the commit message survive.
- A patch that no longer applies cleanly on the pinned baseline
  fails CI — fix the patch, never the baseline pin, to resolve it.

## Current patches

| File | What it does | Why |
| --- | --- | --- |
| `0001-remove-hosted-services-and-infra.patch` | Deletes the hosted services and cloud layer: `services/` (site, files, update), `packages/function`, `infra/`, `sst.config.ts` and `sst-env.d.ts`. | Part of the CLI/TUI-only delta (patches 0001–0004, one decision): openmux supports CLI and TUI only; every other environment is deleted totally — not hidden or disabled. Split into four files only so no single patch exceeds GitHub's 100 MB per-file limit. |
| `0002-remove-web-gui-and-gui-packages.patch` | Deletes the web GUI and the GUI-only packages: `packages/app`, `packages/ui`, `packages/session-ui`, `packages/gui-plugins` and `packages/stories`. | Same CLI/TUI-only delta as above. |
| `0003-remove-desktop-docs-sdk-and-other-envs.patch` | Deletes the Electron desktop app (`packages/desktop`), the docs site (`packages/web`), the SDK (`packages/sdk`), the VS Code extension (`sdks/vscode`), `packages/stats`, and the desktop browser plugin (`packages/plugin-browser`). | Same CLI/TUI-only delta as above. |
| `0004-remove-all-references-to-deleted-envs.patch` | Removes every reference to the deleted environments in the remaining tree: the web UI embedded into the CLI build and served by its server (`app-assets`/`web-ui` bundling), the CLI `pair` and `acp` commands, the server pairing endpoints, the plugin GUI SDK and GUI-bundle plumbing, the workerd server entry, root workspaces/scripts/catalog and the regenerated `bun.lock`, plus CI/release/nix/docs references. The internal API server the CLI/TUI run on stays; it now serves only its API. | Same CLI/TUI-only delta as above — deletion is total, references included, so nothing in the remaining tree points at an environment that no longer exists. |
| `0005-keep-only-opencode-free-models-and-custom-providers.patch` | Removes every built-in provider and model except the OpenCode Free Models and user-defined custom providers: the bundled models.dev snapshot is trimmed to provider `opencode` with only its 47 free models, the runtime models.dev fetch, the build-time live-catalog bundling and the persistent catalog cache are removed, catalog ingestion drops every non-`opencode` provider and every non-free model regardless of source, the provider adapters in `packages/ai` and the provider-specific core plugins (GitHub Copilot, Modal, Claude Agent, Bedrock, Azure, OpenRouter, xAI, the OpenAI/Codex OAuth plugin, local-server discovery, and the other built-in provider plugins) are deleted, and `disableFree` (`OPENCODE_DISABLE_FREE_MODELS`) is removed so free models always remain. Custom providers and models defined in config keep working through the kept generic adapters (Anthropic, OpenAI, OpenAI-compatible and the OpenCode decisions entrypoint). | Boss's second patch decision: openmux ships only OpenCode Free Models built in; everything else a user wants comes from their own config. Deletion is total — catalog, enforcement in code, and adapters — not UI hiding. |
| `0006-add-termux-bionic-native-build.patch` | Adds a native Android (Termux/Bionic) build target, `linux-arm64-android`, compiled against Bun's official android runtime so the binary is a PIE executable for `/system/bin/linker64`. The PTY and parcel-watcher bindings use their designed fallbacks (no android builds exist upstream; shells run without a PTY, file watching degrades to `fs.watch`). OpenTUI publishes no android asset, so the build embeds a prepared asset tree — the linux-arm64-musl render library, which needs only `libc.so` (Bionic's own SONAME), made Bionic-compatible with patchelf (libm.so plus a small compat shim as NEEDED entries, `$ORIGIN` rpath) — and the CLI extracts it to its cache at startup and re-execs once with `OTUI_ASSET_ROOT` set (the renderer reads an environment fixed at process start). The shim, `packages/cli/script/bionic-compat.c`, supplies the three symbols Bionic lacks — `__errno_location`, `copy_file_range`, `pthread_tryjoin_np` (the last two are dead imports in @opentui/core 0.8.1, verified by disassembly) — and disables Bionic heap pointer tagging, whose tagged pointers exceed the safe-integer range of Bun's FFI. A build-time audit fails the android build if the render library's imports drift from `packages/cli/script/opentui-musl-undefined.txt`; a `patchedDependencies` entry maps @opentui/core's asset descriptor for android to the musl asset. | Boss's patch decision of 2026-11-10: openmux runs natively in Termux on his phone — no proot or glibc shim layer. Materials from second parties only: OpenCode upstream, official Bun, the Termux project. Verified end-to-end on the maintainer's Redmi Note 9 (Android 12): the TUI renders with no manual setup, and sessions, the search/read/shell tools and sqlite persistence all work natively. The android build additionally needs patchelf and an Android NDK compiler (or a prebuilt shim via `OPENCODE_BIONIC_SHIM`); the release workflow builds it on the x64 runner as a third asset — a pure cross-compile, since the NDK's host tools are x86_64 binaries and nothing in the android build executes the produced binary on the host. (Renumbered from 0010 to 0006 in the 2026-11-10 restructure; content unchanged.) |

Withdrawn patches: the single-system-prompt patch, the tool-descriptions patch, the agent-prompts-and-permissions patch and the delegation-enforcement patch — numbered 0006–0009 in the pre-restructure flat layout (that numbering is retired; 0006 now denotes the Termux patch) — were removed from the series on 2026-11-09 by the maintainer's decision; the series then ended at 0005. Their content remains available in releases v0.4.0–v0.7.0 and in this repository's git history.
