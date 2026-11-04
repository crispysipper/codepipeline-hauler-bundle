#!/usr/bin/env bash
# Install tools needed to build and upload a Hauler haul on Amazon Linux 2023.
set -euo pipefail

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64 | amd64) GOARCH=amd64 ;;
  aarch64 | arm64) GOARCH=arm64 ;;
  *) echo "unsupported arch: $ARCH" >&2; exit 1 ;;
esac

TOOLS_DIR="${TOOLS_DIR:-/usr/local/bin}"
TMP="${TMPDIR:-/tmp}/hauler-tools"
mkdir -p "$TOOLS_DIR" "$TMP"
cd "$TMP"

need() { command -v "$1" >/dev/null 2>&1; }

if ! need yq; then
  curl -fsSL -o yq "https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_linux_${GOARCH}"
  install -m 0755 yq "$TOOLS_DIR/yq"
fi

if ! need hauler; then
  HAULER_VER="${HAULER_VERSION:-1.0.7}"
  curl -fsSL -o hauler.tgz \
    "https://github.com/hauler-dev/hauler/releases/download/v${HAULER_VER}/hauler_${HAULER_VER}_linux_${GOARCH}.tar.gz"
  tar -xzf hauler.tgz
  install -m 0755 hauler "$TOOLS_DIR/hauler"
fi

echo "tools ready:"
for c in yq hauler aws; do
  printf '  %-10s %s\n' "$c" "$(command -v "$c" || echo MISSING)"
done
