#!/bin/bash
# Run xfwl4 TTY backend test in podman container
# Uses Fedora 44 container with direct device access
set -euo pipefail

REPO_ROOT="/var/home/james/dev/xfce-wayland"
INSTALL_PREFIX="$REPO_ROOT/install"
CONTAINER_NAME="xfwl4-tty-test"

echo "=== xfwl4 TTY Backend Container Test (Fedora 44) ==="
echo ""

# Stop existing container
podman stop "$CONTAINER_NAME" 2>/dev/null || true
podman rm "$CONTAINER_NAME" 2>/dev/null || true

echo "Note: libseat session will fail in containers (needs real TTY/logind)"
echo "This validates the build, deps, and initialization up to DRM/KMS handoff."
echo ""

# Run Fedora 44 container with:
# - Direct access to /dev/dri/* (DRM devices)
# - Direct access to /dev/input/* (input devices)
# - Shared install prefix
# - Privileged for DRM access
podman run -it --name "$CONTAINER_NAME" \
    --privileged \
    --device /dev/dri \
    --device /dev/input \
    --device /dev/kvm \
    -v "$INSTALL_PREFIX:$INSTALL_PREFIX:ro" \
    -e INSTALL_PREFIX="$INSTALL_PREFIX" \
    -e PKG_CONFIG_PATH="$INSTALL_PREFIX/lib64/pkgconfig:$INSTALL_PREFIX/share/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig" \
    -e LD_LIBRARY_PATH="$INSTALL_PREFIX/lib64" \
    -e XDG_DATA_DIRS="$INSTALL_PREFIX/share:/usr/share" \
    -e PATH="$INSTALL_PREFIX/bin:/usr/local/bin:/usr/bin" \
    docker.io/library/fedora:44 \
    bash -c '
echo "=== Fedora 44 Container Setup ==="
cat /etc/fedora-release
echo ""

# Create machine-id for dbus
echo "00000000000000000000000000000001" > /etc/machine-id

# Symlink libdisplay-info.so.3 -> .2 (ABI compat)
ln -sf /usr/lib64/libdisplay-info.so.3 /usr/lib64/libdisplay-info.so.2 2>/dev/null || true

echo "Installing dependencies..."
dnf install -y --setopt=tsflags=nodocs --setopt=install_weak_deps=False \
    libseat libinput libdrm mesa-libgbm \
    gtk3 cairo pango libxkbcommon wayland-devel \
    gdk-pixbuf2 at-spi2-atk \
    libX11 libSM libICE startup-notification \
    libdisplay-info dbus-daemon 2>&1 | tail -3

echo ""
echo "DRM devices available:"
ls -la /dev/dri/

echo ""
echo "Checking library dependencies..."
ldd $INSTALL_PREFIX/bin/xfwl4-tty 2>&1 | grep "not found" | head -5 || echo "All dependencies satisfied"

echo ""
echo "Starting dbus session..."
export DBUS_SESSION_BUS_ADDRESS=$(dbus-daemon --session --fork --print-address 2>/dev/null | tail -1)
echo "DBUS: $DBUS_SESSION_BUS_ADDRESS"

echo ""
echo "Starting xfconfd..."
$INSTALL_PREFIX/bin/xfconfd &
sleep 1

echo ""
echo "Running xfwl4 TTY backend (10s timeout)..."
timeout 10 $INSTALL_PREFIX/bin/xfwl4-tty --backend=tty --no-session 2>&1 || true

echo ""
echo "=== Container test complete ==="
'

echo ""
echo "Container stopped."
echo "To clean up: podman rm -f $CONTAINER_NAME"
