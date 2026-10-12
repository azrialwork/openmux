#!/bin/sh
# install.sh -- Install native Bionic OpenCode for Termux (Android/aarch64).
#
# One-line install:
#   curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB_USER/opencode-termux/main/install.sh | bash
# Pinned version:
#   curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB_USER/opencode-termux/main/install.sh | bash -s -- --version 2.0.22
#
# What it does: downloads the release tarball built by .github/workflows/build.yml,
# verifies its SHA-256 checksum, and extracts it into $PREFIX. Short and readable
# on purpose -- inspect it before piping to bash.
set -eu

REPO="YOUR_GITHUB_USER/opencode-termux" # <-- set this to your GitHub repo
ASSET="opencode-android-aarch64.tar.gz"
SUMS="SHA256SUMS.txt"
VERSION="latest"

usage() {
  echo "usage: install.sh [--version X.Y.Z]"
  echo "  Installs native Bionic OpenCode for Termux (Android aarch64)."
}

while [ $# -gt 0 ]; do
  case "$1" in
    --version)
      [ $# -ge 2 ] || { echo "error: --version needs an argument" >&2; usage >&2; exit 1; }
      VERSION="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

# 1. Termux check
if [ -n "${PREFIX:-}" ] && [ -d "$PREFIX" ]; then
  :
elif [ -d /data/data/com.termux/files/usr ]; then
  PREFIX=/data/data/com.termux/files/usr
else
  echo "error: Termux not detected (\$PREFIX is not set)" >&2
  exit 1
fi

# 2. Architecture check
ARCH="$(uname -m)"
if [ "$ARCH" != "aarch64" ]; then
  echo "error: unsupported architecture: $ARCH (only aarch64 is built)" >&2
  exit 1
fi

# 3. Tool check
for t in curl tar; do
  command -v "$t" >/dev/null 2>&1 || { echo "error: '$t' is required but not installed" >&2; exit 1; }
done
if command -v sha256sum >/dev/null 2>&1; then
  SHA256="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  SHA256="shasum -a 256"
else
  echo "error: 'sha256sum' or 'shasum' is required but not installed" >&2
  exit 1
fi

# 4. Download
if [ "$VERSION" = "latest" ]; then
  BASE="https://github.com/$REPO/releases/latest/download"
else
  BASE="https://github.com/$REPO/releases/download/v$VERSION"
fi
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM
echo "downloading OpenCode $VERSION for Termux (aarch64)..."
curl -fsSL -o "$TMP/$ASSET" "$BASE/$ASSET"
curl -fsSL -o "$TMP/$SUMS" "$BASE/$SUMS"

# 5. Verify checksum before extracting (never extract unverified bytes)
echo "verifying checksum..."
(cd "$TMP" && $SHA256 -c "$SUMS")

# 6. Install into $PREFIX
echo "installing into $PREFIX..."
tar -xzf "$TMP/$ASSET" -C "$PREFIX"
chmod +x "$PREFIX/bin/opencode"

# 7. ripgrep: required by OpenCode for file search
if ! command -v rg >/dev/null 2>&1; then
  if command -v pkg >/dev/null 2>&1; then
    echo "installing ripgrep (required by OpenCode)..."
    pkg install -y ripgrep
  else
    echo "warning: 'rg' (ripgrep) not found and 'pkg' unavailable; install it manually" >&2
  fi
fi

echo ""
echo "done. next steps:"
echo "  export ANTHROPIC_API_KEY=\"sk-...\"   # or OPENAI_API_KEY"
echo "  opencode --version"
echo "  opencode"
