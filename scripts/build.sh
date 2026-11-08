#!/usr/bin/env bash
# Build the openmux CLI binary for one target, entirely from the
# pinned upstream baseline + the patches in this repository.
#
# Usage:
#   scripts/build.sh <target> <output-dir>
#
#   <target>      OpenCode target name, e.g. linux-x64, linux-arm64,
#                 darwin-arm64, darwin-x64, windows-x64
#   <output-dir>  Directory that receives opencode-<target>.tar.gz
#                 (or .zip contents on windows — not used yet)
#
# Requires: git, jq, bun 1.4.4 and node >= 22 on PATH.
# This is the single build entry point: GitHub Actions calls this
# script, and so can a local machine. No other build path exists.
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 <target> <output-dir>" >&2
  exit 1
fi

target="$1"
output_dir="$(mkdir -p "$2" && cd "$2" && pwd)"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

# 1. Upstream baseline + delta.
"$repo_root/scripts/apply-patches.sh" "$work_dir/src"

# 2. Dependencies (frozen, exactly as upstream pinned them).
cd "$work_dir/src"
bun install --frozen-lockfile

# 3. Build the CLI for the requested target only.
#    build.ts selects the target from OPENCODE_TARGET and uses the
#    models catalog committed in upstream when
#    OPENCODE_MODELS_SNAPSHOT is unset, so the build is reproducible.
#    OPENCODE_VERSION stamps the binary with the real upstream
#    version (the pinned baseline tag, e.g. 2.2.6): without it the
#    upstream build script falls back to a synthetic
#    0.0.0-detached-<build> version because the build checkout is a
#    detached clone.
version="$(jq -r .baseline_tag "$repo_root/upstream.json" | sed 's/^v//')"
cd "$work_dir/src/packages/cli"
OPENCODE_TARGET="$target" OPENCODE_VERSION="$version" bun run script/build.ts

# 4. Smoke test the produced binary, then package it.
binary="$work_dir/src/packages/cli/dist/cli-$target/bin/opencode"
if [ ! -f "$binary" ]; then
  echo "ERROR: expected binary not found at $binary" >&2
  find "$work_dir/src/packages/cli/dist" -maxdepth 3 -type f | head -n 50 >&2
  exit 1
fi
chmod +x "$binary"
"$binary" --version

baseline="$(jq -r .baseline_tag "$repo_root/upstream.json")"
archive="openmux-$baseline-$target.tar.gz"
tar -czf "$output_dir/$archive" -C "$(dirname "$binary")" "$(basename "$binary")"
(cd "$output_dir" && sha256sum "$archive" > "$archive.sha256")

echo "Built $output_dir/$archive"
