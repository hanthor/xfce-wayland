#!/bin/bash
# Run xfwl4 in nested X11 mode (inside current X11 session)
set -euo pipefail

REPO_ROOT="/var/home/james/dev/xfce-wayland"
INSTALL="$REPO_ROOT/install"

export PKG_CONFIG_PATH="$INSTALL/lib64/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig"
export LD_LIBRARY_PATH="$INSTALL/lib64"
export PATH="$REPO_ROOT/bin:$PATH"

PROFILE="${1:-debug}"
BUILDDIR="$REPO_ROOT/xfwl4/builddir-${PROFILE}/xfwl4/$PROFILE/xfwl4"

if [ ! -f "$BUILDDIR" ]; then
    echo "Binary not found: $BUILDDIR"
    echo "Run: $REPO_ROOT/build.sh $PROFILE"
    exit 1
fi

echo "Running xfwl4 (x11 backend)..."
echo "Binary: $BUILDDIR"
echo ""

exec "$BUILDDIR" --backend x11
