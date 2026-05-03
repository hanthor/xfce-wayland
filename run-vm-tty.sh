#!/bin/bash
# Run xfwl4 TTY backend test in QEMU VM
# Requires: qemu-system-x86_64, Fedora Server ISO installed in xfwl4-test.qcow2
set -euo pipefail

REPO_ROOT="/var/home/james/dev/xfce-wayland"
DISK="$REPO_ROOT/xfwl4-test.qcow2"
INSTALL_PREFIX="$REPO_ROOT/install"

echo "=== xfwl4 TTY Backend VM Test ==="
echo ""

if [[ ! -f "$DISK" ]]; then
    echo "ERROR: VM disk not found at $DISK"
    echo "Run ./setup-vm.sh first to create and install the VM"
    exit 1
fi

echo "Starting QEMU VM with GPU passthrough..."
echo ""
echo "Instructions:"
echo "1. VM boots to login prompt"
echo "2. Login as root (or your user)"
echo "3. Switch to TTY2: Ctrl+Alt+F2"
echo "4. Run: $INSTALL_PREFIX/bin/xfwl4-tty --backend=tty --no-session"
echo ""
echo "Environment will be pre-configured via /etc/environment"
echo ""

# QEMU with virtio-gpu (emulated DRM device)
qemu-system-x86_64 \
    -enable-kvm \
    -m 4096 \
    -smp 4 \
    -drive file="$DISK",format=qcow2 \
    -device virtio-gpu-pci \
    -device virtio-tablet \
    -device virtio-keyboard \
    -netdev user,id=net0,hostfwd=tcp:127.0.0.1:5555-:22 \
    -device virtio-net-pci,netdev=net0 \
    -vga none \
    -serial mon:stdio \
    -display none \
    -daemonize

echo "VM started in background"
echo "SSH into VM: ssh -p 5555 root@localhost"
echo ""
echo "Then inside VM:"
echo "  export INSTALL_PREFIX=/var/home/james/dev/xfce-wayland/install"
echo "  export PKG_CONFIG_PATH=\$INSTALL_PREFIX/lib64/pkgconfig:\$INSTALL_PREFIX/share/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig"
echo "  export LD_LIBRARY_PATH=\$INSTALL_PREFIX/lib64:\$LD_LIBRARY_PATH"
echo "  export XDG_DATA_DIRS=\$INSTALL_PREFIX/share:/usr/share"
echo "  export PATH=\$INSTALL_PREFIX/bin:\$PATH"
echo ""
echo "  # Start xfconfd"
echo "  xfconfd &"
echo "  sleep 1"
echo ""
echo "  # Start xfwl4 TTY backend"
echo "  xfwl4-tty --backend=tty --no-session"
echo ""
echo "To stop VM: killall qemu-system-x86_64"
