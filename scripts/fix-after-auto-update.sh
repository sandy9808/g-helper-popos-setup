#!/usr/bin/env bash
set -euo pipefail

# Restore G-Helper after accidental in-app auto-update on Pop!_OS 22.04.
# Release binaries need GLIBC 2.38; Pop 22.04 only has 2.35.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${GHELPER_LINUX_DIR:-$HOME/g-helper-linux}"
INSTALL_BIN="/opt/ghelper/ghelper"
BACKUP="$REPO_DIR/dist/ghelper.bak"
LOCAL_BUILD="$REPO_DIR/dist/ghelper"

needs_rebuild() {
  local bin="$1"
  [[ ! -x "$bin" ]] && return 0
  if "$bin" 2>&1 | head -1 | grep -q 'GLIBC_2.38'; then
    return 0
  fi
  if ! "$bin" --help &>/dev/null; then
    # ghelper has no --help; try a quick ldd check on libm
    if ldd "$bin" 2>&1 | grep -q 'GLIBC_2.38'; then
      return 0
    fi
  fi
  # strings check for glibc requirement
  if strings "$bin" 2>/dev/null | grep -q 'GLIBC_2.38'; then
    return 0
  fi
  return 1
}

echo "==> Stopping ghelper (if running)..."
pkill -x ghelper 2>/dev/null || true
sleep 1

echo "==> Removing stale native libs..."
sudo rm -f /opt/ghelper/libSkiaSharp.so /opt/ghelper/libHarfBuzzSharp.so

restore_binary() {
  local src="$1"
  echo "==> Restoring compatible binary from $src"
  sudo cp "$src" "$INSTALL_BIN"
  sudo chown "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" "$INSTALL_BIN"
  chmod +x "$INSTALL_BIN"
}

if [[ -f "$BACKUP" ]] && ! needs_rebuild "$BACKUP"; then
  restore_binary "$BACKUP"
elif [[ -f "$LOCAL_BUILD" ]] && ! needs_rebuild "$LOCAL_BUILD"; then
  restore_binary "$LOCAL_BUILD"
else
  echo "==> No good local binary found — rebuilding from source..."
  "$SCRIPT_DIR/build-and-install.sh"
  exit $?
fi

"$SCRIPT_DIR/disable-auto-update.sh"

echo ""
echo "==> Verifying..."
"$SCRIPT_DIR/check-ghelper.sh"

"$SCRIPT_DIR/install-scripts.sh" 2>/dev/null || true

echo ""
echo "==> Fixed. Launch with: start-ghelper.sh"
echo "    Tip: decline in-app updates on Pop 22.04 — they download GLIBC 2.38 binaries."