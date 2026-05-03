#!/bin/bash
# Integration test: run xfwl4 in nested mode and spawn a Wayland client
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

# Find a free display number
DISPLAY_NUM=$(( $(ls /tmp/.X11-unix/ 2>/dev/null | grep -c ^X || echo 0) + 99 ))

echo "=== xfwl4 Integration Test ($PROFILE) ==="
echo "Xvfb display: :$DISPLAY_NUM"
echo ""

# Start Xvfb
Xvfb :$DISPLAY_NUM -screen 0 1280x1024x24 &
XVFB_PID=$!
trap "kill $XVFB_PID 2>/dev/null; wait $XVFB_PID 2>/dev/null" EXIT
sleep 1

# Run xfwl4 in background
XDG_DATA_DIRS="$HOME/.local/share:$XDG_DATA_DIRS"
DISPLAY=:$DISPLAY_NUM "$BUILDDIR" --backend winit > /tmp/xfwl4-test.log 2>&1 &
XFWL4_PID=$!
trap "kill $XFWL4_PID 2>/dev/null; kill $XVFB_PID 2>/dev/null; wait $XFWL4_PID 2>/dev/null; wait $XVFB_PID 2>/dev/null; pkill -f XWayland 2>/dev/null" EXIT

# Wait for Wayland socket
echo "Waiting for Wayland socket..."
for i in $(seq 1 30); do
    if ls /run/user/*/wayland-* 2>/dev/null | grep -q .; then
        WAYLAND_SOCKET=$(ls /run/user/*/wayland-* 2>/dev/null | grep -v lock | head -1 | xargs basename)
        echo "Socket found: $WAYLAND_SOCKET"
        break
    fi
    sleep 0.2
done

if [ -z "${WAYLAND_SOCKET:-}" ]; then
    echo "ERROR: Wayland socket not created in 6 seconds"
    cat /tmp/xfwl4-test.log
    exit 1
fi

# Wait for main loop to start
sleep 1

# Check initialization
if grep -q "Initialization completed" /tmp/xfwl4-test.log; then
    echo "✓ xfwl4 initialized successfully"
else
    echo "✗ xfwl4 failed to initialize"
    grep -E "ERROR|panic" /tmp/xfwl4-test.log | tail -5
    exit 1
fi

# Check XWayland
if grep -q "XWayland" /tmp/xfwl4-test.log; then
    echo "✓ XWayland spawned"
else
    echo "⚠ XWayland not spawned (may still be initializing)"
fi

# Spawn a Wayland client
echo ""
echo "Spawning weston-terminal..."
WAYLAND_DISPLAY=$WAYLAND_SOCKET timeout 3 weston-terminal 2>/dev/null
CLIENT_EXIT=$?

if [ $CLIENT_EXIT -eq 124 ]; then
    echo "✓ weston-terminal ran for 3 seconds (killed by timeout = connected)"
elif [ $CLIENT_EXIT -eq 1 ]; then
    echo "✗ weston-terminal failed to connect"
else
    echo "? weston-terminal exited with code $CLIENT_EXIT"
fi

# Check xfwl4 logs for any crashes
if grep -q "panic\|segfault\|fatal" /tmp/xfwl4-test.log 2>/dev/null; then
    echo "✗ xfwl4 crashed during client test"
    grep -E "panic|segfault|fatal" /tmp/xfwl4-test.log | tail -5
else
    echo "✓ xfwl4 stable during client test"
fi

# Clean up happens via trap
echo ""
echo "=== Test Complete ==="
echo "Log: /tmp/xfwl4-test.log"
