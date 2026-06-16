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

## Scripts (in this repo)

All scripts live in **`scripts/`** and use the **exact names below**:

| Script | What it does |
|--------|----------------|
| [`scripts/install-deps.sh`](scripts/install-deps.sh) | Install apt packages + .NET 10 SDK |
| [`scripts/build-and-install.sh`](scripts/build-and-install.sh) | Clone, build, install g-helper-linux + install scripts |
| [`scripts/install-scripts.sh`](scripts/install-scripts.sh) | Copy all scripts to `/usr/local/bin/` (same names) |
| [`scripts/fix-after-auto-update.sh`](scripts/fix-after-auto-update.sh) | **Run if you hit auto-update by mistake** |
| [`scripts/check-ghelper.sh`](scripts/check-ghelper.sh) | Verify binary is compatible with Pop 22.04 |
| [`scripts/disable-auto-update.sh`](scripts/disable-auto-update.sh) | Set `skip_update_prompt=1` in config |
| [`scripts/start-ghelper.sh`](scripts/start-ghelper.sh) | **Safe launcher** — sets DBUS/DISPLAY env (prevents startup segfault) |

```bash
git clone https://github.com/sandy9808/g-helper-popos-setup.git
cd g-helper-popos-setup
chmod +x scripts/*.sh

# First-time install
./scripts/install-deps.sh
./scripts/build-and-install.sh

# Launch (from repo or after install-scripts.sh, from anywhere)
./scripts/start-ghelper.sh
# or: start-ghelper.sh

# Accidentally clicked auto-update?
./scripts/fix-after-auto-update.sh

# Quick health check anytime
./scripts/check-ghelper.sh
```

After `./scripts/build-and-install.sh`, scripts are also installed to `/usr/local/bin/` with the **same `.sh` names** — run `start-ghelper.sh` from any directory.

---

## Quick reference (copy-paste)

```bash
git clone https://github.com/sandy9808/g-helper-popos-setup.git
cd g-helper-popos-setup
chmod +x scripts/*.sh
./scripts/install-deps.sh
./scripts/build-and-install.sh
./scripts/start-ghelper.sh
```

---

## Prerequisites

```bash
# Or just run: ./scripts/install-deps.sh
sudo apt update
sudo apt install -y \
  clang zlib1g-dev upx-ucl \
  libpipewire-0.3-dev pkg-config libwayland-dev \
  build-essential

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
# Or just run: ./scripts/build-and-install.sh
git clone https://github.com/utajum/g-helper-linux.git
cd g-helper-linux
export PATH="$HOME/.dotnet:$PATH"
./build.sh
```

Build output lands in `dist/ghelper` (~15 MB, Native AOT).

Test before installing:

```bash
./scripts/start-ghelper.sh   # after install-scripts.sh copies it
# or from build dir: ./dist/ghelper  (needs DBUS env — prefer start-ghelper.sh)
```

---

## Install system-wide

```bash
sudo ./install/install-local.sh   # inside g-helper-linux repo
# or: ./scripts/build-and-install.sh   # does everything from this repo
```

This deploys:

| Path | Purpose |
|------|---------|
| `/opt/ghelper/ghelper` | Main binary |
| `/usr/local/bin/ghelper` | Symlink to binary |
| `/usr/local/bin/start-ghelper.sh` | Safe launcher script (same as repo) |
| `/etc/udev/rules.d/90-ghelper.rules` | sysfs permissions |
| `/etc/systemd/system/ghelper-gpu-boot.service` | Apply GPU mode at boot |
| `~/.config/autostart/ghelper.desktop` | Autostart on login |

Launch:

```bash
./scripts/start-ghelper.sh
# or after install-scripts.sh:
start-ghelper.sh
```

> Do **not** run bare `/opt/ghelper/ghelper` from scripts/SSH without DBUS session env — it can segfault ~5s after startup. Always use `start-ghelper.sh`.

---

## Extra fix: stale SkiaSharp libraries

```bash
# Or: ./scripts/fix-after-auto-update.sh
sudo rm -f /opt/ghelper/libSkiaSharp.so /opt/ghelper/libHarfBuzzSharp.so
sudo cp dist/ghelper /opt/ghelper/ghelper
sudo chown "$USER:$USER" /opt/ghelper/ghelper
```

Symptom:

```text
The version of the native libSkiaSharp library (88.1) is incompatible with this version of SkiaSharp.
```

---

## Disable auto-updates (important on Pop 22.04)

```bash
./scripts/disable-auto-update.sh
```

Or manually in `~/.config/ghelper/config.json`:

```json
{
  "skip_update_prompt": 1
}
```

To update later, rebuild — **do not** use the in-app updater on Pop 22.04:

```bash
./scripts/build-and-install.sh
```

---

## Autostart

`~/.config/autostart/ghelper.desktop` should use the launcher script:

```ini
Exec=/usr/local/bin/start-ghelper.sh
```

Or from the repo clone:

```ini
Exec=/home/USER/g-helper-popos-setup/scripts/start-ghelper.sh
```

---

## Accidental auto-update — will it break?

| Action | Risk |
|--------|------|
| Saw update prompt, clicked **No** / dismissed | No issue |
| Downloaded update but **did not restart** | `/opt/ghelper/ghelper` may still be fine |
| Downloaded update **and restarted** ghelper | Binary may need GLIBC 2.38 → **won't start** |

```bash
./scripts/check-ghelper.sh
./scripts/fix-after-auto-update.sh    # if check fails
./scripts/disable-auto-update.sh
```

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

Change refresh rate in **Settings → Displays** (Pop!_OS), not inside G-Helper.

### GPU Ultimate mode

Requires a **reboot** after switching in G-Helper.

### Startup segfault from terminal/SSH

Use `./scripts/start-ghelper.sh` — sets `DBUS_SESSION_BUS_ADDRESS` and `XDG_RUNTIME_DIR`.

### Stale lock file

```bash
rm -f /run/user/$UID/ghelper.lock
./scripts/start-ghelper.sh
```

---

## Uninstall

```bash
cd g-helper-linux
sudo ./install/install-local.sh --uninstall
```

---

## Alternatives

| Tool | Notes |
|------|-------|
| [g-helper-linux](https://github.com/utajum/g-helper-linux) | Closest to Windows G-Helper; GUI + tray |
| [asusctl](https://gitlab.com/asus-linux/asusctl) + [supergfxctl](https://gitlab.com/asus-linux/supergfxctl) | CLI-focused ASUS Linux stack |

---

## Author

Setup documented for [sandy9808](https://github.com/sandy9808) — ASUS TUF Gaming F15 FX507VV on Pop!_OS 22.04.