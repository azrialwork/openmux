# Patches

This directory holds the entire delta that `openmux` carries on top
of the upstream baseline pinned in `../upstream.json`.

## Rules

- One logical change per patch file.
- Files are named `NNNN-short-description.patch`, numbered in apply
  order (`0001-...`, `0002-...`, ...).
- `series` lists the patch filenames in apply order, one per line.
  Lines starting with `#` and blank lines are ignored.
- Every patch is listed in the table below with what it does and why.
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
