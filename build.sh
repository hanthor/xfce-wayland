#!/bin/bash
# xfwl4 build script - builds all components and xfwl4
set -euo pipefail

REPO_ROOT="/var/home/james/dev/xfce-wayland"
INSTALL="$REPO_ROOT/install"
PKG_CONFIG_PATH="$INSTALL/lib64/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig"
LD_LIBRARY_PATH="$INSTALL/lib64"
PATH="$REPO_ROOT/bin:$PATH"

export PKG_CONFIG_PATH LD_LIBRARY_PATH PATH

PROFILE="${1:-debug}"
echo "Building xfwl4 ($PROFILE profile)..."

cd "$REPO_ROOT/xfwl4"

if [ "$PROFILE" = "release" ]; then
    BUILDDIR="builddir-release"
else
    BUILDDIR="builddir"
fi

if [ ! -d "$BUILDDIR" ]; then
    meson setup "$BUILDDIR" --prefix="$INSTALL" -Dbuildtype="$PROFILE"
fi

ninja -C "$BUILDDIR"

echo ""
echo "Build complete."
BIN="$REPO_ROOT/xfwl4/$BUILDDIR/xfwl4/$PROFILE/xfwl4"
echo "Binary: $BIN ($(du -h "$BIN" | cut -f1))"
echo ""
echo "Usage:"
echo "  # Test in nested mode (winit backend, runs inside current session):"
echo "    $REPO_ROOT/run-winit.sh [$PROFILE]"
echo ""
echo "  # Integration test (Xvfb + Wayland client):"
echo "    $REPO_ROOT/test-nested.sh [$PROFILE]"
echo ""
echo "  # Quick rebuild (incremental):"
echo "    $REPO_ROOT/build.sh [$PROFILE]"
