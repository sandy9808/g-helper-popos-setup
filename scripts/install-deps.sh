#!/usr/bin/env bash
set -euo pipefail

# Install build dependencies for G-Helper Linux on Pop!_OS 22.04 / Ubuntu 22.04

echo "==> Installing native build packages..."
sudo apt-get update -qq
sudo apt-get install -y \
  clang zlib1g-dev upx-ucl \
  libpipewire-0.3-dev pkg-config libwayland-dev \
  build-essential curl

DOTNET_DIR="${DOTNET_ROOT:-$HOME/.dotnet}"
if [[ ! -x "$DOTNET_DIR/dotnet" ]]; then
  echo "==> Installing .NET 10 SDK to $DOTNET_DIR ..."
  curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
  bash /tmp/dotnet-install.sh --channel 10.0 --install-dir "$DOTNET_DIR"
fi

export PATH="$DOTNET_DIR:$PATH"

if ! grep -qF '.dotnet' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/.dotnet:$PATH"' >> "$HOME/.bashrc"
  echo "==> Added .NET to ~/.bashrc"
fi

echo ""
echo "==> Done. Versions:"
echo "    dotnet: $(dotnet --version)"
echo "    glibc:  $(ldd --version | head -1)"
echo ""
echo "Next: ./scripts/build-and-install.sh"