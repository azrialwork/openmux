# shellcheck shell=bash
# Shared helpers for the openmux scripts. This file is SOURCED by the
# entry-point scripts in scripts/, never executed directly.
#
# Provides:
#   OPENMUX_ROOT      Absolute path of this repository's root.
#   upstream_get KEY  Print a string field of upstream.json,
#                     e.g. `upstream_get baseline_tag` -> v2.2.6.
#   die MESSAGE       Print "ERROR: MESSAGE" to stderr and exit 1.
#
# OPENMUX_ROOT is derived from this file's own location (scripts/lib/,
# so the root is two levels up), which keeps it correct no matter
# which script sources it or what the caller's working directory is.

OPENMUX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export OPENMUX_ROOT

upstream_get() {
  jq -r ".$1" "$OPENMUX_ROOT/upstream.json"
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}
