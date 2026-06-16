#!/usr/bin/env bash
set -euo pipefail

# Install repo scripts to /usr/local/bin keeping the same names as in README.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="/usr/local/bin"

for script in \
  install-deps.sh \
  build-and-install.sh \
  fix-after-auto-update.sh \
  check-ghelper.sh \
  disable-auto-update.sh \
  start-ghelper.sh; do
  sudo install -m 755 "$SCRIPT_DIR/$script" "$DEST/$script"
  echo "==> Installed $DEST/$script"
done

echo ""
echo "Run from anywhere, e.g.: start-ghelper.sh"