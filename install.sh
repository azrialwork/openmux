#!/usr/bin/env bash
# Install openmux (the `opencode` CLI) from a GitHub Release of
# azrialwork/openmux.
#
#   curl -fsSL https://raw.githubusercontent.com/azrialwork/openmux/main/install.sh | bash
#
# What it does:
#   1. Detects the platform target of this machine:
#        Termux on Android (aarch64)  -> linux-arm64-android
#        Linux x86_64                 -> linux-x64
#        Linux aarch64                -> linux-arm64
#      (Those are the three targets openmux releases build.)
#   2. Downloads that target's archive from the chosen release,
#      verifies it against the release's SHA256SUMS, and installs
#      the `opencode` binary.
#   3. Reports each step as it completes; on a terminal the output
#      is coloured (disable with NO_COLOR), off a terminal it is
#      plain text suitable for logs.
#
# Environment:
#   OPENMUX_VERSION     Release to install, e.g. v1.0.0.
#                       Default: the latest release.
#   OPENMUX_INSTALL_DIR Where to put the binary.
#                       Default: $PREFIX/bin in Termux,
#                       ~/.local/bin elsewhere.
#   NO_COLOR            Set to disable coloured output.
#
# Requires: curl, tar, sha256sum (or shasum), uname.
set -euo pipefail

repo="azrialwork/openmux"
started=$SECONDS

# ---------------------------------------------------------------------
# Presentation. Colour only on a real terminal; the step symbols are
# plain UTF-8 and print either way.
# ---------------------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-}" != "dumb" ]; then
  c_reset=$'\033[0m' c_bold=$'\033[1m' c_dim=$'\033[2m'
  c_accent=$'\033[38;5;75m' c_ok=$'\033[38;5;42m'
  c_err=$'\033[38;5;203m' c_warn=$'\033[38;5;179m'
else
  c_reset= c_bold= c_dim= c_accent= c_ok= c_err= c_warn=
fi

rule="$(printf '─%.0s' $(seq 1 46))"

banner() {
  printf '\n  %s◆%s %sopenmux%s %s— installer%s\n' \
    "$c_accent" "$c_reset" "$c_bold" "$c_reset" "$c_dim" "$c_reset"
  printf '  %sOpenCode delta: CLI/TUI only · free models · Termux native%s\n' "$c_dim" "$c_reset"
  printf '  %s%s%s\n\n' "$c_dim" "$rule" "$c_reset"
}

# step LABEL DETAIL — one completed step, label aligned.
step() {
  printf '  %s✓%s %s%-9s%s %s\n' "$c_ok" "$c_reset" "$c_bold" "$1" "$c_reset" "$2"
}

# pending LABEL DETAIL — work in progress (long steps only).
pending() {
  printf '  %s↓%s %s%-9s%s %s\n' "$c_accent" "$c_reset" "$c_bold" "$1" "$c_reset" "$2"
}

warn() {
  printf '  %s!%s %s\n' "$c_warn" "$c_reset" "$*" >&2
}

die() {
  printf '\n  %s✗ ERROR:%s %s\n' "$c_err" "$c_reset" "$*" >&2
  exit 1
}

human_size() {
  awk -v b="$1" 'BEGIN {
    if (b >= 1048576) printf "%.1f MB", b / 1048576
    else if (b >= 1024) printf "%.1f KB", b / 1024
    else printf "%d B", b
  }'
}

file_size() {
  stat -c %s "$1" 2>/dev/null || stat -f %z "$1"
}

elapsed() {
  local s=$((SECONDS - started))
  if [ "$s" -ge 60 ]; then printf '%dm %ds' $((s / 60)) $((s % 60)); else printf '%ds' "$s"; fi
}

banner

command -v curl >/dev/null 2>&1 || die "curl is required but not on PATH"

# ---------------------------------------------------------------------
# 1. Platform target and install directory.
# ---------------------------------------------------------------------
os="$(uname -s)"
arch="$(uname -m)"
is_termux=false
if [ -n "${TERMUX_VERSION:-}" ] || [ -n "${TERMUX_API:-}" ] ||
  case "${PREFIX:-}" in *com.termux*) true ;; *) false ;; esac ||
  [ "$(uname -o 2>/dev/null || true)" = "Android" ]; then
  is_termux=true
fi

if [ "$is_termux" = true ]; then
  case "$arch" in
    aarch64|arm64) target="linux-arm64-android" ;;
    *) die "Termux is supported on aarch64 only; this device reports $arch" ;;
  esac
  install_dir="${OPENMUX_INSTALL_DIR:-${PREFIX:-$HOME/.local}/bin}"
  platform_label="Termux (Android) · $arch"
elif [ "$os" = "Linux" ]; then
  case "$arch" in
    x86_64|amd64) target="linux-x64" ;;
    aarch64|arm64) target="linux-arm64" ;;
    *) die "unsupported CPU architecture: $arch" ;;
  esac
  install_dir="${OPENMUX_INSTALL_DIR:-$HOME/.local/bin}"
  platform_label="Linux · $arch"
else
  die "unsupported platform: $os $arch — openmux releases build linux-x64, linux-arm64 and linux-arm64-android (Termux) only"
fi
step "Platform" "$platform_label → target $target"

# ---------------------------------------------------------------------
# 2. Release: resolve the version, then take the exact archive name
#    for this target from the release's SHA256SUMS (the name embeds
#    the upstream baseline: openmux-v2.2.6-<target>.tar.gz).
# ---------------------------------------------------------------------
version="${OPENMUX_VERSION:-}"
version_note="pinned"
if [ -z "$version" ]; then
  latest_json="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest")" ||
    die "could not query the latest release of $repo"
  version="$(printf '%s' "$latest_json" | grep -o '"tag_name": *"[^"]*"' | head -n 1 | sed 's/.*: *"//; s/"$//')"
  [ -n "$version" ] || die "could not parse the latest release tag"
  version_note="latest"
fi
case "$version" in v*) ;; *) version="v$version" ;; esac
base_url="https://github.com/$repo/releases/download/$version"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
cd "$work_dir"

curl -fsSL --retry 3 -o SHA256SUMS "$base_url/SHA256SUMS" ||
  die "could not download SHA256SUMS for $version — does that release exist?"

archive=""
expected_sum=""
while read -r sum name; do
  case "$name" in
    *-"$target".tar.gz) archive="$name"; expected_sum="$sum" ;;
  esac
done < SHA256SUMS
[ -n "$archive" ] || die "release $version has no archive for target $target"

baseline="${archive#openmux-}"
baseline="${baseline%-"$target".tar.gz}"
step "Release" "openmux $version ($version_note) · baseline OpenCode $baseline"

# ---------------------------------------------------------------------
# 3. Download (resumable), verify, install.
# ---------------------------------------------------------------------
pending "Download" "$archive"

# -C - lets a retried attempt resume the partial download instead of
# starting over (the archives are ~80-90 MB; phone connections drop).
progress=()
[ -t 2 ] && progress=(-#)
curl -fsSL "${progress[@]}" -C - --retry 3 -o "$archive" "$base_url/$archive" ||
  die "could not download $archive"
step "Download" "$(human_size "$(file_size "$archive")") complete"

if command -v sha256sum >/dev/null 2>&1; then
  grep -F " $archive" SHA256SUMS | sha256sum -c - >/dev/null ||
    die "checksum mismatch for $archive (expected SHA-256 $expected_sum) — refusing to install"
else
  grep -F " $archive" SHA256SUMS | shasum -a 256 -c - >/dev/null ||
    die "checksum mismatch for $archive (expected SHA-256 $expected_sum) — refusing to install"
fi
step "Verify" "SHA-256 checksum matched"

tar -xzf "$archive"
[ -f opencode ] || die "$archive did not contain an opencode binary"

mkdir -p "$install_dir"
install -m 0755 opencode "$install_dir/opencode"
step "Install" "$install_dir/opencode"

# ---------------------------------------------------------------------
# Summary.
# ---------------------------------------------------------------------
installed_version="$("$install_dir/opencode" --version 2>/dev/null || true)"
[ -n "$installed_version" ] || installed_version="opencode (version check failed)"

printf '\n  %s%s%s\n' "$c_dim" "$rule" "$c_reset"
printf '  %s✓%s %sDone in %s%s — %s is ready.\n' \
  "$c_ok" "$c_reset" "$c_bold" "$(elapsed)" "$c_reset" "$installed_version"
printf '    %sBinary%s  %s\n' "$c_dim" "$c_reset" "$install_dir/opencode"
case ":$PATH:" in
  *":$install_dir:"*)
    printf '    %sRun%s     opencode\n' "$c_dim" "$c_reset"
    ;;
  *)
    printf '    %sRun%s     %s/opencode\n' "$c_dim" "$c_reset" "$install_dir"
    warn "$install_dir is not on your PATH — add it to run \`opencode\` from anywhere."
    ;;
esac
printf '\n'
