#!/bin/bash
# Boot the xfwl4 test VM (after installation)
set -euo pipefail

REPO_ROOT="/var/home/james/dev/xfce-wayland"
DISK="$REPO_ROOT/xfwl4-test.qcow2"

if [ ! -f "$DISK" ]; then
    echo "Disk not found. Run setup-vm.sh first."
    exit 1
fi

qemu-system-x86_64 \
    -enable-kvm \
    -m 4096 \
    -smp 4 \
    -drive file="$DISK",format=qcow2 \
    -device virtio-vga \
    -device virtio-tablet \
    -netdev user,id=net0 \
    -device virtio-net-pci,netdev=net0
