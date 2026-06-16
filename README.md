# G-Helper on Pop!_OS 22.04 (ASUS TUF Gaming F15)

Guide for running **G-Helper Linux** on Pop!_OS 22.04 LTS when the pre-built release binary does not work.

Tested on:

- **OS:** Pop!_OS 22.04 LTS (Ubuntu Jammy base)
- **Kernel:** 6.12.10
- **Laptop:** ASUS TUF Gaming F15 FX507VV (RTX 4060 + Intel)
- **GLIBC:** 2.35 (Pop 22.04 ships this; release binaries often need 2.38+)

---

## Why the release installer breaks

The official one-liner downloads a pre-compiled binary from GitHub Releases:

```bash
curl -sL https://raw.githubusercontent.com/utajum/g-helper-linux/master/install/install.sh | sudo bash
```

On Pop!_OS 22.04, that binary typically fails with:

```text
/lib/x86_64-linux-gnu/libm.so.6: version `GLIBC_2.38' not found (required by /opt/ghelper/ghelper)
```

**Cause:** Release builds are compiled on newer distros (GLIBC 2.38+). Pop 22.04 only has GLIBC 2.35.

**Fix:** Build [g-helper-linux](https://github.com/utajum/g-helper-linux) from source on your machine so it links against your local GLIBC.

> **Note:** The Windows [seerge/g-helper](https://github.com/seerge/g-helper) project does **not** run on Linux. Use **g-helper-linux** instead — it is a native Linux port with similar features (performance modes, fans, GPU switching, battery limit, keyboard RGB, etc.).

---

## Prerequisites

```bash
# Native build tools
sudo apt update
sudo apt install -y \
  clang zlib1g-dev upx-ucl \
  libpipewire-0.3-dev pkg-config libwayland-dev \
  build-essential

# .NET 10 SDK (not in Pop 22.04 repos — install via Microsoft script)
curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
bash /tmp/dotnet-install.sh --channel 10.0 --install-dir "$HOME/.dotnet"
echo 'export PATH="$HOME/.dotnet:$PATH"' >> ~/.bashrc
export PATH="$HOME/.dotnet:$PATH"
```

Verify:

```bash
dotnet --version   # should show 10.0.x
ldd --version      # Pop 22.04 → 2.35
lsmod | grep asus  # asus_nb_wmi, asus_wmi should be loaded
```

---

## Build from source

```bash
git clone https://github.com/utajum/g-helper-linux.git
cd g-helper-linux
export PATH="$HOME/.dotnet:$PATH"
./build.sh
```

Build output lands in `dist/ghelper` (~15 MB, Native AOT).

Test before installing:

```bash
./dist/ghelper
```

You should see log lines like `G-Helper Linux initialized` and `Tray icon created successfully`. A second launch reports *"another instance is already running"* — that is normal.

---

## Install system-wide

```bash
sudo ./install/install-local.sh
```

This deploys:

| Path | Purpose |
|------|---------|
| `/opt/ghelper/ghelper` | Main binary |
| `/usr/local/bin/ghelper` | Symlink |
| `/etc/udev/rules.d/90-ghelper.rules` | sysfs permissions |
| `/etc/systemd/system/ghelper-gpu-boot.service` | Apply GPU mode at boot |
| `~/.config/autostart/ghelper.desktop` | Autostart on login |

Launch:

```bash
ghelper
```

Or use the system tray icon / application menu entry.

---

## Extra fix: stale SkiaSharp libraries

If you previously installed the release binary, old native libraries may remain in `/opt/ghelper/`:

```text
/opt/ghelper/libSkiaSharp.so
/opt/ghelper/libHarfBuzzSharp.so
```

These conflict with the new build (version mismatch crash on startup). Remove them:

```bash
sudo rm -f /opt/ghelper/libSkiaSharp.so /opt/ghelper/libHarfBuzzSharp.so
sudo cp dist/ghelper /opt/ghelper/ghelper
sudo chown "$USER:$USER" /opt/ghelper/ghelper
```

Symptom without this fix:

```text
The version of the native libSkiaSharp library (88.1) is incompatible with this version of SkiaSharp.
```

---

## Disable auto-updates (important on Pop 22.04)

The in-app updater downloads release binaries built on newer distros — they will break again on Pop 22.04.

In G-Helper: **Settings → disable "Don't check for updates on startup"** (or set in config):

```json
// ~/.config/ghelper/config.json
{
  "skip_update_prompt": 1
}
```

To update later, rebuild from source and copy the binary:

```bash
cd g-helper-linux
export PATH="$HOME/.dotnet:$PATH"
./build.sh
sudo cp dist/ghelper /opt/ghelper/ghelper
```

**Do not** let the app auto-update itself on Pop 22.04.

---

## Autostart

Ensure `~/.config/autostart/ghelper.desktop` points to the system install:

```ini
Exec=/opt/ghelper/ghelper
```

Not a path under your build directory (`~/g-helper-linux/dist/ghelper`).

---

## Features confirmed on FX507VV

| Feature | Status |
|---------|--------|
| Performance modes (Silent / Balanced / Turbo) | Yes |
| Custom fan curves (2 fans) | Yes |
| GPU modes (Eco / Standard / Optimized / Ultimate) | Yes |
| MUX switch | Yes (reboot required for Ultimate) |
| Battery charge limit | Yes |
| Keyboard RGB (TUF) | Yes |
| NVIDIA power limits / dynamic boost | Yes |
| Panel overdrive | Yes |

---

## Known issues

### Refresh rate crash (segfault)

Changing refresh rate inside G-Helper (xrandr backend) can segfault on some X11 setups:

```text
SetRefreshRate(144Hz) via xrandr backend
Segmentation fault (core dumped)
```

**Workaround:** Change refresh rate in **Settings → Displays** (Pop!_OS) instead of inside G-Helper.

### GPU Ultimate mode

Switching to **Ultimate** requires a **reboot**. G-Helper shows a notification; the `ghelper-gpu-boot.service` applies the MUX switch before the display manager starts.

### Auto-update overwrote my build

If `dist/ghelper` suddenly needs GLIBC 2.38 again, restore from the build backup:

```bash
cp dist/ghelper.bak dist/ghelper   # if .bak exists from self-update
# or rebuild: ./build.sh
```

---

## Uninstall

```bash
cd g-helper-linux
sudo ./install/install-local.sh --uninstall
# type YES when prompted
```

User config in `~/.config/ghelper/` is preserved.

---

## Alternatives

| Tool | Notes |
|------|-------|
| [g-helper-linux](https://github.com/utajum/g-helper-linux) | Closest to Windows G-Helper; GUI + tray |
| [asusctl](https://gitlab.com/asus-linux/asusctl) + [supergfxctl](https://gitlab.com/asus-linux/supergfxctl) | CLI-focused ASUS Linux stack |

For TUF F15 on Pop!_OS, **g-helper-linux built from source** is the most complete option.

---

## Quick reference (copy-paste)

```bash
# Full install from scratch on Pop!_OS 22.04
sudo apt install -y clang zlib1g-dev upx-ucl libpipewire-0.3-dev pkg-config libwayland-dev build-essential
curl -sSL https://dot.net/v1/dotnet-install.sh | bash -s -- --channel 10.0 --install-dir "$HOME/.dotnet"
export PATH="$HOME/.dotnet:$PATH"

git clone https://github.com/utajum/g-helper-linux.git
cd g-helper-linux
./build.sh
sudo rm -f /opt/ghelper/libSkiaSharp.so /opt/ghelper/libHarfBuzzSharp.so 2>/dev/null
sudo ./install/install-local.sh

# Disable auto-updates
mkdir -p ~/.config/ghelper
# Add "skip_update_prompt": 1 to ~/.config/ghelper/config.json

ghelper
```

---

## Author

Setup documented for [sandy9808](https://github.com/sandy9808) — ASUS TUF Gaming F15 FX507VV on Pop!_OS 22.04.