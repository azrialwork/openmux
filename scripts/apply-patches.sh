#!/usr/bin/env bash
# Clone upstream OpenCode at the pinned baseline and apply every
# patch listed in patches/series, in order.
#
# Usage:
#   scripts/apply-patches.sh <target-dir>
#
# <target-dir> must not exist yet, or must be an empty directory.
# All build work (local or GitHub Actions) starts from the tree this
# script produces — the delta is applied exactly once, exactly here.
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <target-dir>" >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_dir="$1"

upstream_url="$(jq -r .upstream_url "$repo_root/upstream.json")"
baseline="$(jq -r .baseline_tag "$repo_root/upstream.json")"

git clone --depth 1 --branch "$baseline" "$upstream_url" "$target_dir"

applied=0
while IFS= read -r patch_file; do
  # Skip blank lines and comments.
  case "$patch_file" in
    ''|'#'*) continue ;;
  esac
  echo "Applying patches/$patch_file"
  git -C "$target_dir" apply --index "$repo_root/patches/$patch_file"
  applied=$((applied + 1))
done < "$repo_root/patches/series"

echo "Applied $applied patch(es) on top of $baseline in $target_dir"
