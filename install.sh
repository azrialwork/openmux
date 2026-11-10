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
#
# Environment:
#   OPENMUX_VERSION     Release to install, e.g. v0.9.0.
#                       Default: the latest release.
#   OPENMUX_INSTALL_DIR Where to put the binary.
#                       Default: $PREFIX/bin in Termux,
#                       ~/.local/bin elsewhere.
#
# Requires: curl, tar, sha256sum (or shasum), uname.
set -euo pipefail

repo="azrialwork/openmux"

die() {
  echo "install.sh: ERROR: $*" >&2
  exit 1
}

command -v curl >/dev/null 2>&1 || die "curl is required but not on PATH"

# --- 1. Platform target and install directory -------------------------
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
elif [ "$os" = "Linux" ]; then
  case "$arch" in
    x86_64|amd64) target="linux-x64" ;;
    aarch64|arm64) target="linux-arm64" ;;
    *) die "unsupported CPU architecture: $arch" ;;
  esac
  install_dir="${OPENMUX_INSTALL_DIR:-$HOME/.local/bin}"
else
  die "unsupported platform: $os $arch — openmux releases build linux-x64, linux-arm64 and linux-arm64-android (Termux) only"
fi

# --- 2. Release version ------------------------------------------------
version="${OPENMUX_VERSION:-}"
if [ -z "$version" ]; then
  echo "Finding the latest openmux release..."
  latest_json="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest")" ||
    die "could not query the latest release of $repo"
  version="$(printf '%s' "$latest_json" | grep -o '"tag_name": *"[^"]*"' | head -n 1 | sed 's/.*: *"//; s/"$//')"
  [ -n "$version" ] || die "could not parse the latest release tag"
fi
case "$version" in v*) ;; *) version="v$version" ;; esac

base_url="https://github.com/$repo/releases/download/$version"
echo "Installing openmux $version ($target) into $install_dir"

# --- 3. Download, verify, install --------------------------------------
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
cd "$work_dir"

curl -fsSL --retry 3 -o SHA256SUMS "$base_url/SHA256SUMS" ||
  die "could not download SHA256SUMS for $version — does that release exist?"

# The archive name embeds the upstream baseline (openmux-v2.2.6-<target>.tar.gz),
# so take the exact name from SHA256SUMS: the entry ending in -<target>.tar.gz.
archive=""
while read -r _sum name; do
  case "$name" in
    *-"$target".tar.gz) archive="$name" ;;
  esac
done < SHA256SUMS
[ -n "$archive" ] || die "release $version has no archive for target $target"

# -C - lets a retried attempt resume the partial download instead of
# starting over (the archives are ~80-90 MB; phone connections drop).
progress=()
[ -t 2 ] && progress=(-#)
curl -fsSL "${progress[@]}" -C - --retry 3 -o "$archive" "$base_url/$archive" ||
  die "could not download $archive"

if command -v sha256sum >/dev/null 2>&1; then
  grep -F " $archive" SHA256SUMS | sha256sum -c - >/dev/null ||
    die "checksum mismatch for $archive — refusing to install"
else
  grep -F " $archive" SHA256SUMS | shasum -a 256 -c - >/dev/null ||
    die "checksum mismatch for $archive — refusing to install"
fi
echo "Checksum verified: $archive"

tar -xzf "$archive"
[ -f opencode ] || die "$archive did not contain an opencode binary"

mkdir -p "$install_dir"
install -m 0755 opencode "$install_dir/opencode"

echo "Installed: $install_dir/opencode"
"$install_dir/opencode" --version

case ":$PATH:" in
  *":$install_dir:"*) ;;
  *) echo "Note: $install_dir is not on your PATH — add it to run \`opencode\` directly." ;;
esac
