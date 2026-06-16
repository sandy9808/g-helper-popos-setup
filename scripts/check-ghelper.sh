#!/usr/bin/env bash
set -euo pipefail

INSTALL_BIN="/opt/ghelper/ghelper"
CONFIG="$HOME/.config/ghelper/config.json"

echo "=== G-Helper health check (Pop!_OS 22.04) ==="
echo ""

echo "GLIBC: $(ldd --version | head -1)"

if [[ ! -x "$INSTALL_BIN" ]]; then
  echo "STATUS: FAIL — $INSTALL_BIN not found"
  echo "FIX:    ./scripts/build-and-install.sh"
  exit 1
fi

if strings "$INSTALL_BIN" 2>/dev/null | grep -q 'GLIBC_2.38'; then
  echo "STATUS: FAIL — binary requires GLIBC 2.38 (auto-update likely overwrote it)"
  echo "FIX:    ./scripts/fix-after-auto-update.sh"
  exit 1
fi

if [[ -f /opt/ghelper/libSkiaSharp.so ]] || [[ -f /opt/ghelper/libHarfBuzzSharp.so ]]; then
  echo "STATUS: WARN — stale libSkiaSharp.so in /opt/ghelper (can crash on start)"
  echo "FIX:    sudo rm -f /opt/ghelper/libSkiaSharp.so /opt/ghelper/libHarfBuzzSharp.so"
fi

if [[ -f "$CONFIG" ]] && grep -q '"skip_update_prompt"[[:space:]]*:[[:space:]]*1' "$CONFIG"; then
  echo "Auto-update: disabled (good)"
else
  echo "Auto-update: ENABLED — risky on Pop 22.04"
  echo "FIX:         ./scripts/disable-auto-update.sh"
fi

if pgrep -x ghelper &>/dev/null; then
  echo "Process:     running (pid $(pgrep -x ghelper))"
else
  echo "Process:     not running"
fi

echo "Binary:      $INSTALL_BIN ($(du -h "$INSTALL_BIN" | cut -f1))"
echo ""
echo "STATUS: OK — compatible with Pop!_OS 22.04"