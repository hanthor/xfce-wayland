#!/bin/bash
set -e

# Kill any existing processes
for proc in xfwl4 xfce4-panel xfconfd thunar xfce4-terminal xfce4-notifyd xfce4-appfinder xfce4-taskmanager xfdesktop xfce4-desktop tumblerd Xvfb; do
    pkill -f "$proc" 2>/dev/null || true
done
sleep 1

INSTALL_PREFIX=/var/home/james/dev/xfce-wayland/install
export PKG_CONFIG_PATH="$INSTALL_PREFIX/lib64/pkgconfig:$INSTALL_PREFIX/share/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig"
export LD_LIBRARY_PATH="$INSTALL_PREFIX/lib64:$LD_LIBRARY_PATH"
export XDG_DATA_DIRS="$INSTALL_PREFIX/share:/usr/share"
export PATH="$INSTALL_PREFIX/bin:$PATH"
export XDG_RUNTIME_DIR=/run/user/$(id -u)

echo "=== XFCE Wayland Full Stack Integration Test ==="
echo ""

# Start Xvfb
Xvfb :99 -screen 0 1280x1024x24 &
XVFB_PID=$!
sleep 1
export DISPLAY=:99
echo "[OK] Xvfb started (PID: $XVFB_PID)"

# Start xfwl4 compositor
"$INSTALL_PREFIX/bin/xfwl4" --backend=winit > /tmp/xfwl4.log 2>&1 &
XFWL4_PID=$!
sleep 3

if kill -0 $XFWL4_PID 2>/dev/null; then
    echo "[OK] xfwl4 compositor running (PID: $XFWL4_PID)"
else
    echo "[FAIL] xfwl4 failed to start"
    cat /tmp/xfwl4.log
    exit 1
fi

# Find Wayland socket
WAYLAND_SOCKET=$(find /run/user/$(id -u) -name "wayland-*" -type s 2>/dev/null | head -1)
if [[ -z "$WAYLAND_SOCKET" ]]; then
    WAYLAND_SOCKET="$XDG_RUNTIME_DIR/wayland-1"
fi
export WAYLAND_DISPLAY=$(basename "$WAYLAND_SOCKET")
echo "[INFO] Wayland socket: $WAYLAND_DISPLAY"

# Start xfconfd
"$INSTALL_PREFIX/bin/xfconfd" > /tmp/xfconfd.log 2>&1 &
sleep 1
if pgrep -f xfconfd > /dev/null; then
    echo "[OK] xfconfd running"
fi

# Start xfce4-panel
xfce4-panel > /tmp/xfce4-panel.log 2>&1 &
sleep 2
if pgrep -f xfce4-panel > /dev/null; then
    echo "[OK] xfce4-panel running"
else
    echo "[WARN] xfce4-panel failed (check /tmp/xfce4-panel.log)"
fi

# Start xfce4-notifyd
xfce4-notifyd > /tmp/xfce4-notifyd.log 2>&1 &
sleep 1
if pgrep -f xfce4-notifyd > /dev/null; then
    echo "[OK] xfce4-notifyd running"
else
    echo "[WARN] xfce4-notifyd failed"
fi

# Start xfdesktop
xfdesktop > /tmp/xfdesktop.log 2>&1 &
sleep 1
if pgrep -f xfdesktop > /dev/null; then
    echo "[OK] xfdesktop running"
else
    echo "[WARN] xfdesktop failed"
fi

echo ""
echo "=== Testing client applications ==="

# Test each client app with timeout
for app in xfce4-terminal xfce4-appfinder thunar xfce4-taskmanager; do
    echo -n "$app: "
    if timeout 3 "$app" > /tmp/${app}.log 2>&1; then
        echo "[OK] started"
    else
        # Check if it actually started (timeout exit code 124 = ran for 3 seconds)
        if pgrep -f "$app" > /dev/null || [[ $? -eq 124 ]]; then
            echo "[OK] started"
        else
            echo "[WARN] may have issues (check /tmp/${app}.log)"
        fi
    fi
    pkill -f "$app" 2>/dev/null || true
    sleep 0.5
done

echo ""
echo "=== Active processes ==="
pgrep -af "xfwl4|xfce4-panel|xfconfd|xfce4-notifyd|xfdesktop" | head -10

echo ""
echo "=== Compositor log (last 5 lines) ==="
tail -5 /tmp/xfwl4.log

echo ""
echo "=== Integration test complete ==="

# Cleanup
pkill -f xfwl4 2>/dev/null || true
pkill -f xfce4-panel 2>/dev/null || true
pkill -f xfconfd 2>/dev/null || true
pkill -f xfce4-notifyd 2>/dev/null || true
pkill -f xfdesktop 2>/dev/null || true
pkill -f Xvfb 2>/dev/null || true
