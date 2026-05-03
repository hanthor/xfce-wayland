# XFCE Wayland Port

This project contains the work toward a native Wayland port of the XFCE desktop environment.

## Project Structure

- **`xfwl4/`** - The core XFCE Wayland compositor, written in Rust using the [Smithay](https://github.com/smithay/smithay) framework
- **`xfce4-libs/`** - XFCE libraries (libxfce4util, libxfce4ui, xfconf) with Wayland-aware modifications
- **`install/`** - Local build/install prefix for development dependencies
- **`themes/`** - Default theme for development testing
- **`vm/`** - QEMU VM configuration for full TTY testing

## Quick Start

### Build

```bash
# Debug profile (full debug info)
./build.sh debug

# Release profile (optimized, 29MB vs 437MB)
./build.sh release
```

### Integration Test (Headless)

Run xfwl4 in Xvfb with a Wayland client:

```bash
./test-nested.sh      # debug profile
./test-nested.sh release
```

This starts Xvfb, launches xfwl4 with the winit backend, and connects weston-terminal.

### Nested Mode (With Display)

Run xfwl4 nested inside a display session:

```bash
./run-winit.sh        # debug profile
./run-winit.sh release
```

If no display is available, Xvfb is started automatically.

### Test (QEMU VM - Full TTY Mode)

For testing the TTY backend (direct DRM/KMS access):

```bash
# One-time setup: creates disk and downloads Fedora ISO
./setup-vm.sh

# Boot the installed VM
./run-vm.sh
```

Inside the VM, install dependencies and build xfwl4, then run on a TTY:
```bash
# Switch to TTY2 (Ctrl+Alt+F2)
./builddir/xfwl4/relwithdebinfo/xfwl4 --backend tty
```

## Build Dependencies

### Host (Bluefin/CentOS 10)

The build system uses a local prefix at `install/` for custom-built dependencies:

| Library | Version | Source | Notes |
|---------|---------|--------|-------|
| pixman | 0.44.0 | Built from source | System version too old |
| libxfce4util | 4.20.1 | `xfce4-libs/libxfce4util` | Meson build |
| libxfce4ui | 4.21.7-dev | `xfce4-libs/libxfce4ui` | Meson build |
| xfconf | 4.21.2 | `xfce4-libs/xfconf` | Meson build |

System packages needed:
- `rust`, `cargo` (via Homebrew)
- `meson`, `ninja-build` (via Homebrew)
- `wayland-devel`, `libdrm-devel`, `libinput-devel`, `libseat-devel`
- `systemd-devel`, `mesa-libgbm-devel`, `libxkbcommon-devel`
- `gtk3-devel`, `gobject-introspection-devel`
- `xorg-x11-server-Xwayland-devel`, `libxcb-devel`

### VM (Fedora Server)

```bash
sudo dnf install -y rust cargo gcc meson ninja-build \
  pkgconf-pkg-config wayland-devel wayland-protocols \
  libdrm-devel libinput-devel libseat-devel systemd-devel \
  mesa-libgbm-devel pixman-devel libxkbcommon-devel \
  gtk3-devel gobject-introspection-devel \
  xorg-x11-server-Xwayland-devel libxcb-devel \
  qemu-kvm qemu-img
```

## xfwl4 Architecture

xfwl4 is a full-featured Wayland compositor implementing the XFCE window manager functionality:

- **Window Management**: Tiling, maximizing, minimizing, fullscreen, shading, sticky windows
- **Workspaces**: Multiple workspaces with keyboard/mouse switching
- **Decorations**: Native window decorations (titlebars) with theming
- **Xwayland**: Full X11 compatibility layer
- **Input**: Keyboard, pointer, touch, tablet support
- **Configuration**: xfconf-based settings, GTK3 integration
- **Backends**:
  - `tty` — Direct DRM/KMS (production use)
  - `winit` — Nested in X11/Wayland (development/testing)
  - `x11` — Nested in X11 (legacy testing)

## Development Workflow

1. **Code changes** in `xfwl4/src/`
2. **Rebuild**: `./build.sh debug` (incremental, fast)
3. **Test nested**: `./test-nested.sh` (headless integration test)
4. **Debug**: Use `RUST_BACKTRACE=1` and `RUST_LOG=debug` env vars
5. **Full test**: Boot VM, test TTY backend

## Current Status

### Working

- ✅ Full build pipeline (debug + release profiles)
- ✅ EGL/OpenGL ES rendering pipeline
- ✅ Wayland compositor initialization
- ✅ XWayland integration
- ✅ Window decoration system (titlebars, buttons)
- ✅ xfconf configuration system
- ✅ Theme loading (rc format, color resolution)
- ✅ Keyboard input handling
- ✅ Output management (1280x800@60Hz)
- ✅ Wayland client connections (weston-terminal tested)
- ✅ UI supervisor process (crash recovery)
- ✅ Integration test suite (headless)

### Known Issues

- EGL BAD_SURFACE errors in nested Xvfb mode (cosmetic, compositor stable)
- UI supervisor process crashes on Xvfb (recovered automatically)
- Theme images are minimal placeholder PNGs (16x16 solid color)
- `activate_action` setting has parse issue (defaults to correct behavior)

### Still Needed for Full XFCE Desktop

- [ ] xfce4-session Wayland port
- [ ] xfce4-panel Wayland port
- [ ] xfdesktop Wayland port
- [ ] Thunar Wayland port
- [ ] Settings daemon (xfsettingsd) Wayland adaptation
- [ ] Screen locker (xfce4-screensaver) Wayland port
- [ ] Power manager Wayland port

## Key Components

### xfwl4 Core (`xfwl4/src/core/`)

- `shell/` — Window management, tiling, workspace logic
- `workspaces/` — Workspace manager, window stacking
- `config/` — xfconf integration, settings parsing
- `focus/` — Keyboard focus management
- `handlers/` — Protocol handlers (xdg_shell, layer_shell, etc.)
- `state.rs` — Main compositor state

### Backends (`xfwl4/src/backend/`)

- `udev/` — Direct DRM/KMS backend (TTY mode)
- `winit/` — Nested backend via winit crate
- `x11/` — X11 nested backend
