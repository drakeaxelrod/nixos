#!/usr/bin/env bash
# Fix NixOS boot from Live ISO - No data loss
# This script mounts the existing system and rebuilds with correct ESP mount point
set -e

echo "=========================================="
echo "NixOS Boot Repair from Live ISO"
echo "=========================================="
echo ""
echo "This script will:"
echo "1. Mount your existing NixOS installation"
echo "2. Chroot into it"
echo "3. Pull latest config from git"
echo "4. Rebuild with SDDM + Plasma + Intel/NVIDIA PRIME"
echo "5. Fix bootloader to use correct ESP mount point"
echo ""
read -p "Press Enter to continue or Ctrl+C to abort..."

# Ensure we're running as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root"
  echo "Please run: sudo $0"
  exit 1
fi

echo ""
echo "Step 1: Mounting filesystems..."
echo "--------------------------------"

# Unmount anything that might be mounted at /mnt
umount -R /mnt 2>/dev/null || true

# Mount root subvolume
echo "Mounting root..."
mount /dev/nvme0n1p2 /mnt -o subvol=@

# Create mount points
echo "Creating mount points..."
mkdir -p /mnt/home
mkdir -p /mnt/nix
mkdir -p /mnt/var/log
mkdir -p /mnt/.snapshots
mkdir -p /mnt/boot/efi

# Mount other subvolumes
echo "Mounting subvolumes..."
mount /dev/nvme0n1p2 /mnt/home -o subvol=@home
mount /dev/nvme0n1p2 /mnt/nix -o subvol=@nix
mount /dev/nvme0n1p2 /mnt/var/log -o subvol=@log
mount /dev/nvme0n1p2 /mnt/.snapshots -o subvol=@snapshots

# Mount ESP at correct location
echo "Mounting ESP at /boot/efi..."
mount /dev/nvme0n1p1 /mnt/boot/efi

# Mount special filesystems for chroot
echo "Mounting special filesystems..."
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys

echo ""
echo "✓ Filesystems mounted successfully"
echo ""
echo "Mount summary:"
mount | grep "/mnt"
echo ""

echo "Step 2: Preparing chroot environment..."
echo "----------------------------------------"

# Copy resolv.conf for network access in chroot
cp /etc/resolv.conf /mnt/etc/resolv.conf

echo ""
echo "Step 3: Entering chroot and rebuilding..."
echo "------------------------------------------"
echo ""
echo "You will now be dropped into a chroot shell."
echo "Run these commands:"
echo ""
echo "  cd /home/draxel/.config/nixos"
echo "  git pull origin main  # or git fetch && git checkout <branch>"
echo "  nixos-rebuild boot --flake .#nixos"
echo "  exit"
echo ""
read -p "Press Enter to enter chroot..."

chroot /mnt /bin/bash

echo ""
echo "Step 4: Cleaning up..."
echo "----------------------"

echo "Unmounting filesystems..."
umount -R /mnt

echo ""
echo "=========================================="
echo "✓ Boot repair complete!"
echo "=========================================="
echo ""
echo "What happened:"
echo "- ESP is now properly mounted at /boot/efi"
echo "- Bootloader (systemd-boot) installed to correct location"
echo "- New generation created with SDDM + Plasma + Intel/NVIDIA PRIME"
echo ""
echo "Next steps:"
echo "1. Type 'reboot' to restart"
echo "2. You should see systemd-boot menu"
echo "3. Select the newest generation (top of list)"
echo "4. SDDM login screen should appear"
echo "5. Login to Plasma 6 desktop"
echo ""
echo "After verifying everything works:"
echo "- You can switch to Limine by changing loader = \"limine\" in config"
echo ""
read -p "Press Enter to continue..."
