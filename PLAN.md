# XFCE Wayland Port - Build & Integration Plan

## Current State

**Core stack (DONE):**
- xfwl4 compositor (winit backend working, tty backend needs VM)
- xfce4-panel, xfce4-session, xfdesktop, xfce4-settings
- thunar (built with `-Dx11=disabled`)
- Core libs: libxfce4ui, libxfce4util, libxfce4windowing, xfconf, garcon, gtk-layer-shell
- All with full GIR introspection support

**Integration test results:** xfwl4 + xfce4-panel + thunar connect successfully to Wayland socket.

## Component Classification

### Tier 1 - Apps with built-in Wayland support (meson `-Dwayland=enabled`)

| Component | Version | Wayland path | Dependencies | Status |
|-----------|---------|--------------|--------------|--------|
| xfce4-terminal | 1.2.0-dev | gtk-layer-shell | vte, libxfce4ui | TODO |
| xfce4-notifyd | 0.9.7-dev | gtk-layer-shell | libnotify, sqlite, systemd | TODO |
| xfce4-power-manager | 4.21.1-dev | wayland-client + protocols | upower-glib, polkit | TODO |
| xfce4-clipman-plugin | panel-plugin | wayland-client | gtk-layer-shell | TODO |

### Tier 2 - Pure GTK3 apps (work on Wayland automatically)

| Component | Version | Notes | Status |
|-----------|---------|-------|--------|
| xfce4-appfinder | 4.21.1-dev | GTK3, garcon menu | TODO |
| xfce4-places-plugin | panel-plugin | Places menu | TODO |
| xfce4-genmon-plugin | panel-plugin | Generic monitoring | TODO |
| xfce4-datetime-plugin | panel-plugin | Clock/date | TODO |
| xfce4-verve-plugin | panel-plugin | Verve commands | TODO |
| xfce4-mount-plugin | panel-plugin | Device mounting | TODO |
| xfce4-cpugraph-plugin | panel-plugin | CPU graph | TODO |
| xfce4-netload-plugin | panel-plugin | Network monitor | TODO |

### Tier 3 - Apps needing `-Dx11=disabled`

| Component | Version | Notes | Status |
|-----------|---------|-------|--------|
| xfce4-taskmanager | panel-plugin | Uses libwnck3 for icons (X11 only) | TODO |
| xfce4-pulseaudio-plugin | panel-plugin | Uses libxfce4windowing | TODO |

### Tier 4 - Services (no windowing, Wayland-compatible)

| Component | Version | Notes | Status |
|-----------|---------|-------|--------|
| tumbler | 4.21.1-dev | Thumbnailer daemon | TODO |

## Build Order (dependency-aware)

### DONE
1. ~~**tumbler**~~ ✅ Built & installed (thumbnailer daemon)
2. ~~**xfce4-appfinder**~~ ✅ Built & installed (pure GTK3)
3. ~~**xfce4-terminal**~~ ✅ Built & installed (Wayland + gtk-layer-shell)
4. ~~**xfce4-notifyd**~~ ✅ Built & installed (Wayland + gtk-layer-shell, sound disabled)
5. ~~**xfce4-power-manager**~~ ✅ Built & installed (Wayland, patched adaptive_sync)
6. ~~**xfce4-places-plugin**~~ ✅ Built & installed
7. ~~**xfce4-genmon-plugin**~~ ✅ Built & installed
8. ~~**xfce4-taskmanager**~~ ✅ Built & installed (x11=disabled, wnck=disabled)
9. ~~**xfce4-clipman-plugin**~~ ✅ Built & installed (Wayland)
10. ~~**xfce4-verve-plugin**~~ ✅ Built & installed
11. ~~**xfce4-mount-plugin**~~ ✅ Built & installed
12. ~~**xfce4-pulseaudio-plugin**~~ ✅ Built & installed (libxfce4windowing)
13. ~~**xfce4-cpugraph-plugin**~~ ✅ Built & installed
14. ~~**xfce4-netload-plugin**~~ ✅ Built & installed

### TODO
- **xfce4-screenshooter-plugin** ✅ Built & installed (found as `xfce4-screenshooter`, includes panel-plugin)
- **xfce4-datetime-plugin** ✅ Built & installed (autotools, patched includes + gettext)

### Notes
- `xdt-gen-visibility` shim created in `bin/` for builds requiring visibility headers
- `adaptive_sync` callback removed from `xfce4-power-manager/common/xfpm-common.c` (protocol mismatch)
- `wlr-protocols` cloned for `xfce4-power-manager` and `xfce4-clipman-plugin`
- `manpage` generation disabled for `xfce4-terminal` (xsltproc network access)
- `xfce4-dev-tools` installed to custom prefix for datetime-plugin autotools build
- `datetime-dialog.c` include path fixed: `xfce-panel-plugin.h` → `libxfce4panel.h`
- `GETTEXT_PACKAGE` added to config.h for datetime-plugin

### Notes
- `xdt-gen-visibility` shim created in `bin/` for builds requiring visibility headers
- `adaptive_sync` callback removed from `xfce4-power-manager/common/xfpm-common.c` (protocol mismatch)
- `wlr-protocols` cloned for `xfce4-power-manager` and `xfce4-clipman-plugin`
- `manpage` generation disabled for `xfce4-terminal` (xsltproc network access)

## Build Configuration

```bash
# Common env (all components)
INSTALL_PREFIX=/var/home/james/dev/xfce-wayland/install
export PKG_CONFIG_PATH="$INSTALL_PREFIX/lib64/pkgconfig:$INSTALL_PREFIX/share/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig"
export LD_LIBRARY_PATH="$INSTALL_PREFIX/lib64:$LD_LIBRARY_PATH"
export XDG_DATA_DIRS="$INSTALL_PREFIX/share:/usr/share"
export PATH="$INSTALL_PREFIX/bin:$PATH"

# Tier 1 (built-in Wayland)
meson setup builddir -Dprefix=$INSTALL_PREFIX -Dwayland=enabled -Dx11=disabled

# Tier 2 (pure GTK3)
meson setup builddir -Dprefix=$INSTALL_PREFIX

# Tier 3 (x11-disabled)
meson setup builddir -Dprefix=$INSTALL_PREFIX -Dx11=disabled

# Tier 4 (services)
meson setup builddir -Dprefix=$INSTALL_PREFIX
```

## Known Issues to Watch

- `ninja install` fails on immutable host → manual `cp` to `$INSTALL_PREFIX/bin/`
- GIR generation needs wrapper scripts for g-ir-scanner/g-ir-compiler
- Theme images may be missing → placeholder generation script available
- Panel plugins install to `$INSTALL_PREFIX/lib64/xfce4/panel/plugins/`

## Installed Binaries Summary (34 total)

| Binary | Purpose | Wayland |
|--------|---------|---------|
| xfwl4 | Compositor | Native |
| xfce4-panel | Panel | Wayland |
| xfce4-session | Session manager | Wayland |
| xfce4-terminal | Terminal | Wayland (gtk-layer-shell) |
| xfce4-appfinder | App launcher | GTK3 |
| xfce4-notifyd | Notifications | Wayland (gtk-layer-shell) |
| xfce4-power-manager | Power management | Wayland |
| xfce4-taskmanager | Task manager | GTK3 (x11=disabled) |
| thunar | File manager | Wayland (x11=disabled) |
| xfdesktop | Desktop | Wayland |
| xfce4-settings | Settings | Wayland |
| xfconfd | Config daemon | N/A |
| tumblerd | Thumbnailer | N/A |
| xfce4-screenshooter | Screenshots | Wayland (gtk-layer-shell) |

## Panel Plugins (23 installed)

actions, applicationsmenu, clipman, clock, cpugraph, datetime, directorymenu, genmon, launcher, mount, netload, notification, pager, places, pulseaudio, screenshooter, separator, showdesktop, systray, tasklist, verve, windowmenu, power-manager

## TTY Backend Status

**Build**: ✅ Compiles with `--no-default-features -F udev -F egl -F xwayland` (19MB release)
**Deployed**: `install/bin/xfwl4-tty` (separate from winit build at `install/bin/xfwl4`)

**Container test (Fedora 44)**:
- ✅ All library dependencies resolved
- ✅ dbus + xfconfd start successfully
- ✅ xfconf initializes
- ✅ UI supervisor starts
- ✅ udev backend starts
- ❌ `libseat` session fails (expected — needs real TTY/logind)

**Test methods**:
- `run-container-tty.sh` — Fedora 44 podman container (validates build/deps/init)
- `run-vm-tty.sh` — QEMU VM with virtio-gpu (full TTY backend test)

**Known fixes applied**:
- cli.rs: compile-time `#[cfg]` guards for backend selection (was runtime `cfg!()`)
- wlr_screencopy.rs: added `udev` to `WlrBufferConstraints.dma` field cfg

## Integration Test Results

Full stack tested via `test-integration.sh`:

| Component | Status | Notes |
|-----------|--------|-------|
| xfwl4 | ✅ Running | winit backend, EGL BAD_SURFACE cosmetic |
| xfconfd | ✅ Running | Config daemon |
| xfce4-panel | ✅ Running | 22 panel plugins available |
| xfce4-notifyd | ✅ Running | Notification daemon |
| xfdesktop | ✅ Running | Desktop background |
| xfce4-terminal | ✅ Connects | GTK3 app on Wayland |
| thunar | ✅ Connects | File manager (x11=disabled) |
| xfce4-appfinder | ✅ Connects | Menu file needed |
| xfce4-taskmanager | ✅ Connects | GTK3 app on Wayland |

**EGL BAD_SURFACE errors** are cosmetic in nested Xvfb mode — compositor remains stable and functional.

## Integration Test Target

Full stack inside xfwl4 winit backend:
1. xfwl4 compositor running
2. xfconfd daemon
3. xfce4-session launching:
   - xfce4-panel (with plugins)
   - xfdesktop (background)
   - xfce4-notifyd (notifications)
4. Manual launch:
   - xfce4-terminal (terminal)
   - thunar (file manager)
   - xfce4-appfinder (app launcher)
