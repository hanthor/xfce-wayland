#!/bin/bash
# Run xfwl4 in nested winit mode (inside Xvfb or current X11 session)
set -euo pipefail

REPO_ROOT="/var/home/james/dev/xfce-wayland"
INSTALL="$REPO_ROOT/install"

export PKG_CONFIG_PATH="$INSTALL/lib64/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig"
export LD_LIBRARY_PATH="$INSTALL/lib64"
export PATH="$REPO_ROOT/bin:$PATH"

PROFILE="${1:-debug}"

if [ "$PROFILE" = "release" ]; then
    BUILDDIR="$REPO_ROOT/xfwl4/builddir-release/xfwl4/release/xfwl4"
else
    BUILDDIR="$REPO_ROOT/xfwl4/builddir/xfwl4/debug/xfwl4"
fi

if [ ! -f "$BUILDDIR" ]; then
    echo "Binary not found: $BUILDDIR"
    echo "Run: $REPO_ROOT/build.sh $PROFILE"
    exit 1
fi

# If no display is available, start Xvfb
if [ -z "${DISPLAY:-}" ]; then
    DISPLAY_NUM=$(( $(ls /tmp/.X11-unix/ 2>/dev/null | grep -c ^X || echo 0) + 99 ))
    echo "Starting Xvfb on display :$DISPLAY_NUM"
    Xvfb :$DISPLAY_NUM -screen 0 1280x1024x24 &
    XVFB_PID=$!
    trap "kill $XVFB_PID 2>/dev/null; wait $XVFB_PID 2>/dev/null" EXIT
    sleep 1
    export DISPLAY=:$DISPLAY_NUM
fi

XDG_DATA_DIRS="$HOME/.local/share:$XDG_DATA_DIRS"
exec "$BUILDDIR" --backend winit
