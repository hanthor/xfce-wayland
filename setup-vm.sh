#!/bin/bash
# Setup QEMU VM for xfwl4 TTY backend testing
set -euo pipefail

REPO_ROOT="/var/home/james/dev/xfce-wayland"
VM_DIR="$REPO_ROOT/vm"
DISK="$REPO_ROOT/xfwl4-test.qcow2"
ISO_URL="https://download.fedoraproject.org/pub/fedora/linux/releases/44/Server/x86_64/iso/Fedora-Server-dvd-x86_64-44-1.6.iso"
ISO="$VM_DIR/fedora.iso"

mkdir -p "$VM_DIR"

echo "=== xfwl4 QEMU Test VM Setup ==="
echo ""

# Step 1: Create disk if needed
if [ ! -f "$DISK" ]; then
    echo "Creating 20GB qcow2 disk..."
    qemu-img create -f qcow2 "$DISK" 20G
fi

# Step 2: Download ISO if needed
if [ ! -f "$ISO" ]; then
    echo "Downloading Fedora Server ISO..."
    curl -L "$ISO_URL" -o "$ISO"
fi

echo ""
echo "=== Boot Options ==="
echo ""
echo "1. Fresh install (first boot with ISO)"
echo "   qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 \\"
echo "     -drive file=$DISK,format=qcow2 \\"
echo "     -drive file=$ISO,format=raw,media=cdrom \\"
echo "     -device virtio-vga -device virtio-tablet \\"
echo "     -netdev user,id=net0 -device virtio-net-pci,netdev=net0"
echo ""
echo "2. Boot installed VM (after installation)"
echo "   qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 \\"
echo "     -drive file=$DISK,format=qcow2 \\"
echo "     -device virtio-vga -device virtio-tablet \\"
echo "     -netdev user,id=net0 -device virtio-net-pci,netdev=net0"
echo ""
echo "=== After VM is set up ==="
echo ""
echo "Inside the VM, install build dependencies:"
echo "  sudo dnf install -y rust cargo gcc meson ninja-build \\"
echo "    pkgconf-pkg-config wayland-devel wayland-protocols \\"
echo "    libdrm-devel libinput-devel libseat-devel systemd-devel \\"
echo "    mesa-libgbm-devel pixman-devel libxkbcommon-devel \\"
echo "    gtk3-devel gobject-introspection-devel \\"
echo "    xorg-x11-server-Xwayland-devel libxcb-devel"
echo ""
echo "Then sync the xfwl4 source and build:"
echo "  # Copy source into VM or clone from git"
echo "  cd xfwl4 && meson setup builddir && ninja -C builddir"
echo ""
echo "Run xfwl4 on a TTY (Ctrl+Alt+F2 to switch):"
echo "  ./builddir/xfwl4/relwithdebinfo/xfwl4 --backend tty"
echo ""
echo "=== Quick Start ==="
echo ""
read -p "Boot VM for installation? (y/N): " choice
if [[ "$choice" =~ ^[Yy] ]]; then
    qemu-system-x86_64 \
        -enable-kvm \
        -m 4096 \
        -smp 4 \
        -drive file="$DISK",format=qcow2 \
        -drive file="$ISO",format=raw,media=cdrom \
        -device virtio-vga \
        -device virtio-tablet \
        -netdev user,id=net0 \
        -device virtio-net-pci,netdev=net0
fi
