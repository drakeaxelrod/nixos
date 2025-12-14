#!/usr/bin/env bash
# NixOS Installation Script for toaster
# LUKS2 + Btrfs RAID 1 across 2x NVMe
#
# Run from NixOS live USB as root:
#   bash install.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Configuration
DISK1="/dev/nvme0n1"
DISK2="/dev/nvme1n1"
EFI_SIZE="1G"
HOSTNAME="toaster"

# Check we're root
[[ $EUID -ne 0 ]] && error "Run as root"

# Check drives exist
[[ ! -b "$DISK1" ]] && error "$DISK1 not found"
[[ ! -b "$DISK2" ]] && error "$DISK2 not found"

echo ""
echo "========================================"
echo "  NixOS Installation: $HOSTNAME"
echo "========================================"
echo ""
echo "This will DESTROY ALL DATA on:"
echo "  - $DISK1"
echo "  - $DISK2"
echo ""
read -p "Type 'yes' to continue: " confirm
[[ "$confirm" != "yes" ]] && error "Aborted"

# ==========================================================================
# Step 1: Partition both drives
# ==========================================================================
info "Partitioning $DISK1..."
parted -s "$DISK1" -- mklabel gpt
parted -s "$DISK1" -- mkpart ESP fat32 1MiB "$EFI_SIZE"
parted -s "$DISK1" -- set 1 esp on
parted -s "$DISK1" -- mkpart primary "$EFI_SIZE" 100%

info "Partitioning $DISK2..."
parted -s "$DISK2" -- mklabel gpt
parted -s "$DISK2" -- mkpart ESP fat32 1MiB "$EFI_SIZE"
parted -s "$DISK2" -- set 1 esp on
parted -s "$DISK2" -- mkpart primary "$EFI_SIZE" 100%

# ==========================================================================
# Step 2: Format EFI partitions
# ==========================================================================
info "Formatting EFI partitions..."
mkfs.fat -F 32 -n EFI "${DISK1}p1"
mkfs.fat -F 32 -n EFI2 "${DISK2}p1"

# ==========================================================================
# Step 3: Create LUKS containers (same password for both!)
# ==========================================================================
info "Creating LUKS container on ${DISK1}p2..."
echo "Enter LUKS passphrase (use the SAME password for both drives!):"
cryptsetup luksFormat --type luks2 "${DISK1}p2"

info "Creating LUKS container on ${DISK2}p2..."
echo "Enter the SAME LUKS passphrase again:"
cryptsetup luksFormat --type luks2 "${DISK2}p2"

# ==========================================================================
# Step 4: Open LUKS containers
# ==========================================================================
info "Opening LUKS containers..."
echo "Enter passphrase for ${DISK1}p2:"
cryptsetup open "${DISK1}p2" cryptroot0

echo "Enter passphrase for ${DISK2}p2:"
cryptsetup open "${DISK2}p2" cryptroot1

# ==========================================================================
# Step 5: Create Btrfs RAID 1
# ==========================================================================
info "Creating Btrfs RAID 1 filesystem..."
mkfs.btrfs -L nixos \
  -d raid1 \
  -m raid1 \
  /dev/mapper/cryptroot0 \
  /dev/mapper/cryptroot1

# ==========================================================================
# Step 6: Mount and create subvolumes
# ==========================================================================
info "Creating Btrfs subvolumes..."
mount /dev/mapper/cryptroot0 /mnt

btrfs subvolume create /mnt/@rootfs
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@persist
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@work
btrfs subvolume create /mnt/@libvirt
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@snapshots

umount /mnt

# ==========================================================================
# Step 7: Mount subvolumes with correct options
# ==========================================================================
info "Mounting subvolumes..."
OPTS="compress=zstd,noatime"
OPTS_NOCOW="nodatacow,noatime"

mount -o subvol=@rootfs,$OPTS /dev/mapper/cryptroot0 /mnt

mkdir -p /mnt/{nix,persist,home,work,boot/efi}
mkdir -p /mnt/var/{lib/libvirt,log,cache,tmp}
mkdir -p /mnt/.snapshots

mount -o subvol=@nix,$OPTS /dev/mapper/cryptroot0 /mnt/nix
mount -o subvol=@persist,$OPTS /dev/mapper/cryptroot0 /mnt/persist
mount -o subvol=@home,$OPTS /dev/mapper/cryptroot0 /mnt/home
mount -o subvol=@work,$OPTS /dev/mapper/cryptroot0 /mnt/work
mount -o subvol=@libvirt,$OPTS_NOCOW /dev/mapper/cryptroot0 /mnt/var/lib/libvirt
mount -o subvol=@log,$OPTS_NOCOW /dev/mapper/cryptroot0 /mnt/var/log
mount -o subvol=@cache,$OPTS /dev/mapper/cryptroot0 /mnt/var/cache
mount -o subvol=@tmp,$OPTS_NOCOW /dev/mapper/cryptroot0 /mnt/var/tmp
mount -o subvol=@snapshots,$OPTS /dev/mapper/cryptroot0 /mnt/.snapshots

# Mount EFI
mount "${DISK1}p1" /mnt/boot/efi

# ==========================================================================
# Step 8: Create directory structure
# ==========================================================================
info "Creating directories..."
mkdir -p /mnt/.snapshots/{home,work,rootfs,libvirt}
mkdir -p /mnt/work/{clients,templates,tools}
chmod 755 /mnt/work

# ==========================================================================
# Step 9: Copy NixOS config
# ==========================================================================
info "Copying NixOS configuration..."
mkdir -p /mnt/etc/nixos
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cp -r "$SCRIPT_DIR"/* /mnt/etc/nixos/
rm -rf /mnt/etc/nixos/scripts  # Don't need install scripts on target

# ==========================================================================
# Step 10: Generate hardware config
# ==========================================================================
info "Generating hardware configuration..."
nixos-generate-config --root /mnt --no-filesystems

# ==========================================================================
# Verification
# ==========================================================================
echo ""
info "Verification:"
echo ""
echo "Mounts:"
mount | grep /mnt
echo ""
echo "Btrfs RAID status:"
btrfs filesystem show
echo ""
echo "Subvolumes:"
btrfs subvolume list /mnt
echo ""

# ==========================================================================
# Step 11: Install NixOS
# ==========================================================================
echo ""
info "Ready to install NixOS!"
echo ""
echo "Run:"
echo "  nixos-install --flake /mnt/etc/nixos#${HOSTNAME} --no-root-passwd"
echo ""
echo "After install completes:"
echo "  reboot"
echo ""
