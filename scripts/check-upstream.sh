#!/usr/bin/env bash
# Check whether a newer upstream OpenCode v2.x.x tag exists than the
# baseline pinned in upstream.json.
#
# Output (stdout):
#   UP_TO_DATE baseline=<tag> latest=<tag>
#   NEW_VERSION_AVAILABLE baseline=<tag> latest=<tag> commit=<sha>
#
# When GITHUB_OUTPUT is set, also writes baseline_tag, latest_tag,
# latest_commit and has_update=true|false to it.
#
# Exit code is 0 in both cases — "a new version exists" is a report,
# not a failure. Non-zero means the check itself failed.
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

upstream_url="$(upstream_get upstream_url)"
baseline="$(upstream_get baseline_tag)"

latest_line="$(git ls-remote --tags --sort=-v:refname "$upstream_url" 'refs/tags/v2.*' | head -n 1)"
if [ -z "$latest_line" ]; then
  echo "ERROR: no v2.* tags found at $upstream_url" >&2
  exit 1
fi

latest_commit="$(printf '%s' "$latest_line" | awk '{print $1}')"
latest_tag="$(printf '%s' "$latest_line" | awk '{print $2}' | sed 's|refs/tags/||')"

has_update=false
if [ "$latest_tag" != "$baseline" ]; then
  has_update=true
  echo "NEW_VERSION_AVAILABLE baseline=$baseline latest=$latest_tag commit=$latest_commit"
else
  echo "UP_TO_DATE baseline=$baseline latest=$latest_tag"
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "baseline_tag=$baseline"
    echo "latest_tag=$latest_tag"
    echo "latest_commit=$latest_commit"
    echo "has_update=$has_update"
  } >> "$GITHUB_OUTPUT"
fi
