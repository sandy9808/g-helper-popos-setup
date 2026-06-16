#!/usr/bin/env bash
set -euo pipefail

# Clone (if needed), build g-helper-linux from source, and install for Pop!_OS 22.04

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${GHELPER_LINUX_DIR:-$HOME/g-helper-linux}"
DOTNET_DIR="${DOTNET_ROOT:-$HOME/.dotnet}"
export PATH="$DOTNET_DIR:$PATH"

if ! command -v dotnet &>/dev/null; then
  echo "ERROR: .NET SDK not found. Run: ./scripts/install-deps.sh"
  exit 1
fi

if [[ ! -d "$REPO_DIR/.git" ]]; then
  echo "==> Cloning g-helper-linux to $REPO_DIR ..."
  git clone https://github.com/utajum/g-helper-linux.git "$REPO_DIR"
fi

echo "==> Building (this takes ~2 minutes)..."
cd "$REPO_DIR"
./build.sh

echo "==> Removing stale SkiaSharp libs (if any)..."
sudo rm -f /opt/ghelper/libSkiaSharp.so /opt/ghelper/libHarfBuzzSharp.so

echo "==> Installing to /opt/ghelper ..."
sudo "$REPO_DIR/install/install-local.sh"

"$SCRIPT_DIR/disable-auto-update.sh"
"$SCRIPT_DIR/check-ghelper.sh"

echo ""
echo "==> Install complete. Launch with: ghelper"