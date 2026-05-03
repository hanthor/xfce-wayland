# Upstream Sources

All components in this monorepo are forked from their upstream repositories.
This file tracks the original sources and current fork status.

## Core Compositor

| Component | Upstream | Fork Status | Notes |
|-----------|----------|-------------|-------|
| [xfwl4](./xfwl4/) | [gitlab.xfce.org/kelnos/xfwl4](https://gitlab.xfce.org/kelnos/xfwl4) | ✅ Forked | Base compositor, main work here |

## XFCE Components (Wayland-ready upstream)

These components already have `ENABLE_WAYLAND` support using `libxfce4windowing` + `gtk-layer-shell`.
They build and run on Wayland with minimal changes needed.

| Component | Upstream | Fork Status | Wayland Support |
|-----------|----------|-------------|-----------------|
| [xfdesktop](./xfdesktop/) | [gitlab.xfce.org/panel/xfdesktop](https://gitlab.xfce.org/panel/xfdesktop) | ✅ Forked | ✅ Built-in |
| [xfce4-panel](./xfce4-panel/) | [gitlab.xfce.org/panel/xfce4-panel](https://gitlab.xfce.org/panel/xfce4-panel) | ✅ Forked | ✅ Built-in |
| [xfce4-session](./xfce4-session/) | [gitlab.xfce.org/session/xfce4-session](https://gitlab.xfce.org/session/xfce4-session) | ✅ Forked | ✅ Built-in |
| [xfce4-settings](./xfce4-settings/) | [gitlab.xfce.org/xfce/xfce4-settings](https://gitlab.xfce.org/xfce/xfce4-settings) | ✅ Forked | ✅ Built-in |

## XFCE Components (Need porting)

| Component | Upstream | Fork Status | Notes |
|-----------|----------|-------------|-------|
| [thunar](./thunar/) | [gitlab.xfce.org/xfce/thunar](https://gitlab.xfce.org/xfce/thunar) | ✅ Forked | X11-only, needs Wayland support |
| [xfwm4](./xfwm4/) | [gitlab.xfce.org/xfce/xfwm4](https://gitlab.xfce.org/xfce/xfwm4) | ✅ Forked | Reference for xfwl4 window management |

## Libraries (Built from source)

| Component | Upstream | Fork Status | Notes |
|-----------|----------|-------------|-------|
| [libxfce4windowing](./xfce4-libs/libxfce4windowing/) | [gitlab.xfce.org/xfce/libxfce4windowing](https://gitlab.xfce.org/xfce/libxfce4windowing) | ✅ Forked | Abstracts X11/Wayland windowing |
| [libxfce4util](./xfce4-libs/libxfce4util/) | [gitlab.xfce.org/xfce/libxfce4util](https://gitlab.xfce.org/xfce/libxfce4util) | ✅ Forked | Core utilities |
| [libxfce4ui](./xfce4-libs/libxfce4ui/) | [gitlab.xfce.org/xfce/libxfce4ui](https://gitlab.xfce.org/xfce/libxfce4ui) | ✅ Forked | UI widgets |
| [xfconf](./xfce4-libs/xfconf/) | [gitlab.xfce.org/xfce/xfconf](https://gitlab.xfce.org/xfce/xfconf) | ✅ Forked | Configuration daemon |
| [garcon](./xfce4-libs/garcon/) | [gitlab.xfce.org/xfce/garcon](https://gitlab.xfce.org/xfce/garcon) | ✅ Forked | Menu handling |
| [gtk-layer-shell](./xfce4-libs/gtk-layer-shell/) | [github.com/wmww/gtk-layer-shell](https://github.com/wmww/gtk-layer-shell) | ✅ Forked | Layer shell protocol for GTK |

## Protocols / Tools

| Component | Upstream | Fork Status | Notes |
|-----------|----------|-------------|-------|
| [wayland-protocols](./xfce4-libs/wayland-protocols/) | [gitlab.freedesktop.org/wayland/wayland-protocols](https://gitlab.freedesktop.org/wayland/wayland-protocols) | ✅ Forked | Standard protocols |
| [wlr-protocols](./xfce4-libs/wlr-protocols/) | [github.com/swaywm/wlr-protocols](https://github.com/swaywm/wlr-protocols) | ✅ Forked | wlroots extensions |
