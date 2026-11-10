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
#
# Environment:
#   OPENMUX_UPSTREAM_URL  Clone from this URL instead of the
#                         upstream_url pinned in upstream.json
#                         (local mirrors, offline work, tests). The
#                         pinned baseline tag is still checked out.
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <target-dir>" >&2
  exit 1
fi

target_dir="$1"
upstream_url="${OPENMUX_UPSTREAM_URL:-$(upstream_get upstream_url)}"
baseline="$(upstream_get baseline_tag)"

git clone --depth 1 --branch "$baseline" "$upstream_url" "$target_dir"

applied=0
while IFS= read -r patch_path; do
  # Skip blank lines and comments.
  case "$patch_path" in
    ''|'#'*) continue ;;
  esac
  echo "Applying patches/$patch_path"
  git -C "$target_dir" apply --check "$OPENMUX_ROOT/patches/$patch_path"
  git -C "$target_dir" apply --index "$OPENMUX_ROOT/patches/$patch_path"
  applied=$((applied + 1))
done < "$OPENMUX_ROOT/patches/series"

echo "Applied $applied patch(es) on top of $baseline in $target_dir"
