#!/usr/bin/env bash
# Launch G-Helper with the session env vars it needs on Pop!_OS / X11.
# Without DBUS + XDG_RUNTIME_DIR, it can segfault shortly after startup.

set -euo pipefail

UID_NUM="$(id -u)"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/${UID_NUM}}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=${XDG_RUNTIME_DIR}/bus}"
export DISPLAY="${DISPLAY:-:1}"

LOCK="${XDG_RUNTIME_DIR}/ghelper.lock"
if [[ -f "$LOCK" ]] && ! pgrep -x ghelper &>/dev/null; then
  rm -f "$LOCK"
fi

if pgrep -x ghelper &>/dev/null; then
  echo "G-Helper is already running."
  exit 0
fi

exec /opt/ghelper/ghelper "$@"