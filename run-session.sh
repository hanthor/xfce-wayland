#!/bin/bash
# Start full XFCE Wayland session (xfwl4 compositor + desktop stack)
# Usage: ./run-session.sh [--nested]
#   --nested: Run inside Xvfb (winit backend, for testing)
set -euo pipefail

INSTALL_PREFIX=/var/home/james/dev/xfce-wayland/install
export PKG_CONFIG_PATH="$INSTALL_PREFIX/lib64/pkgconfig:$INSTALL_PREFIX/share/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig"
export LD_LIBRARY_PATH="$INSTALL_PREFIX/lib64:${LD_LIBRARY_PATH:-}"
export XDG_DATA_DIRS="$INSTALL_PREFIX/share:/usr/share"
export PATH="$INSTALL_PREFIX/bin:$PATH"
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_TYPE=wayland
export GDK_BACKEND=wayland
export QT_QPA_PLATFORM=wayland

NESTED=false
for arg in "$@"; do
    case "$arg" in
        --nested) NESTED=true ;;
    esac
done

# Cleanup on exit
cleanup() {
    echo "Shutting down..."
    pkill -f xfwl4 2>/dev/null || true
    pkill -f xfce4-session 2>/dev/null || true
    pkill -f xfce4-panel 2>/dev/null || true
    pkill -f xfconfd 2>/dev/null || true
    pkill -f xfce4-notifyd 2>/dev/null || true
    pkill -f xfdesktop 2>/dev/null || true
    pkill -f xfce4-power-manager 2>/dev/null || true
    pkill -f thunar-volman 2>/dev/null || true
    pkill -f tumblerd 2>/dev/null || true
    pkill -f Xvfb 2>/dev/null || true
}
trap cleanup EXIT

# Kill existing processes
for proc in xfwl4 xfce4-session xfce4-panel xfconfd xfce4-notifyd xfdesktop xfce4-power-manager thunar-volman tumblerd Xvfb; do
    pkill -f "$proc" 2>/dev/null || true
done
sleep 1

echo "=== XFCE Wayland Session ==="
echo ""

if [[ "$NESTED" == true ]]; then
    echo "Starting nested session (Xvfb + winit backend)..."
    Xvfb :99 -screen 0 1920x1080x24 &
    XVFB_PID=$!
    sleep 1
    export DISPLAY=:99
    XFWL4_CMD="$INSTALL_PREFIX/bin/xfwl4 --backend=winit"
else
    echo "Starting TTY session (direct DRM/KMS)..."
    echo "Requires: sudo, real TTY, no existing display server"
    XFWL4_CMD="$INSTALL_PREFIX/bin/xfwl4-tty --backend=tty --no-session"
fi

echo ""
echo "Starting xfconfd..."
xfconfd &
sleep 1

echo "Starting tumblerd..."
tumblerd &
sleep 0.5

echo "Starting xfwl4 compositor..."
$XFWL4_CMD &
XFWL4_PID=$!
sleep 3

# Wait for Wayland socket
for i in $(seq 1 10); do
    SOCKET=$(find /run/user/$(id -u) -name "wayland-*" -type s 2>/dev/null | head -1)
    if [[ -n "$SOCKET" ]]; then
        export WAYLAND_DISPLAY=$(basename "$SOCKET")
        break
    fi
    sleep 1
done

if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
    echo "[ERROR] No Wayland socket found!"
    exit 1
fi

echo "Wayland socket: $WAYLAND_DISPLAY"
echo ""

# Start desktop components
echo "Starting xfce4-panel..."
xfce4-panel &
sleep 1

echo "Starting xfdesktop..."
xfdesktop &
sleep 1

echo "Starting xfce4-notifyd..."
xfce4-notifyd &
sleep 0.5

echo "Starting thunar-volman..."
thunar-volman &
sleep 0.5

echo ""
echo "=== Session ready ==="
echo ""
echo "Running processes:"
pgrep -af "xfwl4|xfce4-panel|xfconfd|xfce4-notifyd|xfdesktop|tumblerd" | head -10
echo ""
echo "Quick commands:"
echo "  xfce4-terminal     - Terminal"
echo "  thunar             - File manager"
echo "  xfce4-appfinder    - App launcher"
echo "  xfce4-screenshooter - Screenshots"
echo ""
echo "Press Ctrl+C to stop session"

# Wait for user to stop
wait
