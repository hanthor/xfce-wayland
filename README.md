# XFCE Wayland Port

This project contains the work toward a native Wayland port of the XFCE desktop environment.

## Project Structure

- **`xfwl4/`** - The core XFCE Wayland compositor, written in Rust using [Smithay](https://github.com/smithay/smithay)
- **`xfce4-libs/`** - XFCE libraries (libxfce4util, libxfce4ui, xfconf, garcon, gtk-layer-shell)
- **`install/`** - Local build/install prefix for development dependencies
- **`themes/`** - Default theme for development testing

## Quick Start

### Build All Components

```bash
# Build all components
./build-all.sh

# Clean and rebuild
./build-all.sh --clean

# Include xfwl4 (winit + tty backends)
./build-all.sh --clean --xfwl4
```

### Run Full Desktop Session

```bash
# Nested mode (inside Xvfb, for testing)
./run-session.sh --nested

# TTY mode (direct DRM/KMS, needs sudo + real console)
sudo ./run-session.sh
```

### Integration Test (Headless)

```bash
./test-integration.sh    # Full stack test: compositor + panel + apps
./run-container-tty.sh   # TTY backend test in Fedora 44 container
```

### QEMU VM (Full TTY Testing)

```bash
# One-time setup: creates disk and downloads Fedora 44 ISO
./setup-vm.sh

# Boot the installed VM (virtio-gpu)
./run-vm-tty.sh
```

## Current Status

### Built & Installed: 47 Binaries + 26 Panel Plugins

| Component | Wayland Support | Status |
|-----------|----------------|--------|
| **Compositor** | | |
| xfwl4 | Native (Rust/Smithay) | ✅ winit + tty backends |
| **Core Desktop** | | |
| xfce4-panel | Wayland | ✅ Built |
| xfce4-session | Wayland | ✅ Built |
| xfdesktop | Wayland | ✅ Built |
| xfce4-settings | Wayland | ✅ Built |
| thunar | GTK3 (x11=disabled) | ✅ Built |
| **Applications** | | |
| xfce4-terminal | Wayland (gtk-layer-shell) | ✅ Built |
| xfce4-notifyd | Wayland (gtk-layer-shell) | ✅ Built |
| xfce4-screenshooter | Wayland (gtk-layer-shell) | ✅ Built |
| xfce4-appfinder | GTK3 | ✅ Built |
| xfce4-taskmanager | GTK3 (x11=disabled) | ✅ Built |
| xfce4-power-manager | Wayland | ✅ Built |
| **Services** | | |
| tumblerd | Thumbnailer | ✅ Built |
| thunar-volman | Volume manager | ✅ Built |
| thunar-archive-plugin | Archive support | ✅ Built |
| **Libraries** | | |
| libxfce4ui, libxfce4util, xfconf | Core libs | ✅ Built + GIR |
| garcon, gtk-layer-shell | Menu/Layer shell | ✅ Built |
| libxfce4windowing | Windowing abstraction | ✅ Built |

### Panel Plugins (26)

actions, applicationsmenu, clipman, clock, cpugraph, datetime, directorymenu, diskperf, genmon, launcher, mount, netload, notification, pager, places, pulseaudio, screenshooter, separator, sensors, showdesktop, systray, tasklist, verve, weather, windowmenu, power-manager

### Integration Test Results

| Component | Status | Notes |
|-----------|--------|-------|
| xfwl4 (winit) | ✅ Running | EGL BAD_SURFACE cosmetic in nested |
| xfwl4 (tty) | ✅ Running | Needs real TTY for libseat |
| xfconfd | ✅ Running | Config daemon |
| xfce4-panel | ✅ Running | 26 plugins available |
| xfce4-notifyd | ✅ Running | Notification daemon |
| xfdesktop | ✅ Running | Desktop background |
| xfce4-terminal | ✅ Connects | Wayland client |
| thunar | ✅ Connects | File manager (x11=disabled) |
| xfce4-appfinder | ✅ Connects | App launcher |
| xfce4-taskmanager | ✅ Connects | GTK3 app |

### Blocked

| Component | Reason |
|-----------|--------|
| xfce4-screensaver | Needs libwlembed (source unavailable) |
| xfce4-wmdet-plugin | Repository removed |

## Build Configuration

```bash
# Environment
INSTALL_PREFIX=/var/home/james/dev/xfce-wayland/install
export PKG_CONFIG_PATH="$INSTALL_PREFIX/lib64/pkgconfig:$INSTALL_PREFIX/share/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig"
export LD_LIBRARY_PATH="$INSTALL_PREFIX/lib64"
export XDG_DATA_DIRS="$INSTALL_PREFIX/share:/usr/share"
export PATH="$INSTALL_PREFIX/bin:$PATH"

# xfwl4 backends
cargo build --release --no-default-features -F winit -F egl -F xwayland   # Nested
cargo build --release --no-default-features -F udev -F egl -F xwayland    # TTY
```

## Scripts

| Script | Purpose |
|--------|---------|
| `build-all.sh` | Batch build all components (`--clean`, `--xfwl4`) |
| `run-session.sh` | Full desktop session (`--nested` or TTY) |
| `test-integration.sh` | Headless full stack test |
| `run-container-tty.sh` | Fedora 44 container TTY test |
| `run-vm-tty.sh` | QEMU VM with virtio-gpu |
| `setup-vm.sh` | QEMU VM provisioning (Fedora 44) |

## Known Issues

- **EGL BAD_SURFACE** in nested Xvfb mode (cosmetic, compositor stable)
- **UI supervisor** crashes on Xvfb (auto-recovered)
- **libseat session** needs real TTY/logind (works in QEMU)
- **Immutable host** (`bootc`): `ninja install` fails → manual `cp` workaround
