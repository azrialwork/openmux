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

_None yet. The delta is empty; builds currently produce upstream
v2.2.6 unchanged._

| File | What it does | Why |
| --- | --- | --- |
| — | — | — |
