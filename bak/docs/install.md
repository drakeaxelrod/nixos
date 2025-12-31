# NixOS Installation Guide

This guide covers installing NixOS on any host defined in this flake.

## Available Hosts

| Host | Description | User | Hardware |
|------|-------------|------|----------|
| **toaster** | Gaming + development workstation | draxel | 9800X3D, RTX 5070 Ti, 2x 2TB NVMe RAID 1, VFIO |
| **honeypot** | Pentesting VM/machine | bamse | Any (default: virtio disk) |
| **poptart** | Barebones developer machine | hollywood | Any (default: /dev/sda) |

---

## Quick Reference

```bash
# Install a host (replace HOST with toaster or honeypot)
nixos-install --flake /tmp/nixos#HOST --no-root-passwd

# Rebuild after changes
sudo nixos-rebuild switch --flake "/etc/nixos#HOST"

# Or use devshell
cd /etc/nixos && nix develop
rebuild HOST
```

---

## Prerequisites

- NixOS minimal ISO on USB ([download latest unstable](https://nixos.org/download))
- Network connection (ethernet recommended)
- This repo (clone from GitHub or copy from USB)

---

## Installing toaster

Gaming/development workstation with VFIO GPU passthrough, LUKS encryption, Btrfs RAID 1.

### Hardware

| Component | Model |
|-----------|-------|
| CPU | AMD Ryzen 7 9800X3D |
| GPU | NVIDIA RTX 5070 Ti (VFIO passthrough) |
| RAM | 64GB DDR5-6000 |
| Storage | 2x Samsung 990 PRO 2TB NVMe (Btrfs RAID 1) |
| Motherboard | ASUS ROG Strix B850-I Gaming WiFi |

### Step 1: Boot and Prepare

```bash
# Boot NixOS USB, login as root

# Connect to network (WiFi if needed)
nmcli device wifi connect "YOUR_SSID" password "YOUR_PASSWORD"

# Verify both NVMe drives detected
lsblk
# Should see: nvme0n1, nvme1n1 (both ~2TB)

# Enable flakes
export NIX_CONFIG="experimental-features = nix-command flakes"
```

### Step 2: Clone Config

```bash
git clone https://github.com/YOUR_USER/nixos /tmp/nixos
cd /tmp/nixos
```

### Step 3: Run Disko

Disko handles partitioning, LUKS encryption, and Btrfs RAID 1:

```bash
# Run disko (prompts for LUKS passphrase - USE SAME PASSWORD FOR BOTH DRIVES)
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko /tmp/nixos/hosts/toaster/disko.nix
```

Disko creates:
- 1GB EFI partition on each drive
- LUKS2 encrypted root on each drive
- Btrfs RAID 1 across both encrypted devices
- 10 subvolumes (@rootfs, @nix, @home, @work, @persist, @libvirt, @log, @cache, @tmp, @snapshots)

### Step 4: Verify Disk Setup

```bash
# Check mounts
mount | grep /mnt

# Check Btrfs RAID
btrfs filesystem show

# Check subvolumes
btrfs subvolume list /mnt
```

### Step 5: Install

```bash
# Copy config to target
mkdir -p /mnt/etc/nixos
cp -r /tmp/nixos/* /mnt/etc/nixos/

# Generate hardware config (disko handles filesystems)
nixos-generate-config --root /mnt --no-filesystems

# Install
nixos-install --flake /mnt/etc/nixos#toaster --no-root-passwd
```

### Step 6: Reboot

```bash
reboot
# Remove USB when prompted, enter LUKS passphrase at boot
```

### Step 7: Post-Install Configuration

```bash
# Login as: draxel / changeme
passwd  # Change immediately!

# Update network interface in vars.nix
ip link  # Find your interface name (e.g., eno1, enp6s0)
sudo nvim /etc/nixos/hosts/toaster/vars.nix
# Update: network.bridge.interface = "YOUR_INTERFACE"

# Find GPU PCI IDs for VFIO
lspci -nn | grep -i nvidia
# Update gpu.vfioIds in vars.nix

# Rebuild
cd /etc/nixos && nix develop
rebuild toaster
```

### TPM2 Enrollment (Optional)

Only after system boots reliably for several days:

```bash
# Enroll TPM + PIN for both drives
sudo systemd-cryptenroll /dev/nvme0n1p2 --tpm2-device=auto --tpm2-with-pin=yes
sudo systemd-cryptenroll /dev/nvme1n1p2 --tpm2-device=auto --tpm2-with-pin=yes

# Generate recovery keys (SAVE OFFLINE!)
sudo systemd-cryptenroll /dev/nvme0n1p2 --recovery-key
sudo systemd-cryptenroll /dev/nvme1n1p2 --recovery-key
```

---

## Installing honeypot

Pentesting machine - can be physical or VM.

### Step 1: Boot and Prepare

```bash
# Boot NixOS USB
export NIX_CONFIG="experimental-features = nix-command flakes"

git clone https://github.com/YOUR_USER/nixos /tmp/nixos
cd /tmp/nixos
```

### Step 2: Check/Update Disk Device

The default disko config uses `/dev/vda` (virtio). For physical machines:

```bash
# Check available disks
lsblk

# If not vda, edit disko.nix
nvim /tmp/nixos/hosts/honeypot/disko.nix
# Change: device = "/dev/sda";  # or nvme0n1, etc.
```

### Step 3: Run Disko

```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko /tmp/nixos/hosts/honeypot/disko.nix
```

Creates:
- 512MB EFI partition
- Btrfs root with subvolumes (@, @home, @nix, @log, @snapshots)

### Step 4: Install

```bash
mkdir -p /mnt/etc/nixos
cp -r /tmp/nixos/* /mnt/etc/nixos/

nixos-generate-config --root /mnt --no-filesystems

nixos-install --flake /mnt/etc/nixos#honeypot --no-root-passwd
```

### Step 5: Reboot and Configure

```bash
reboot

# Login as: bamse / changeme
passwd

# Update vars.nix if needed (CPU type, network interface)
sudo nvim /etc/nixos/hosts/honeypot/vars.nix
```

---

## Installing poptart

Barebones developer machine with Moonlight game streaming client.

### Step 1: Boot and Prepare

```bash
# Boot NixOS USB
export NIX_CONFIG="experimental-features = nix-command flakes"

git clone https://github.com/YOUR_USER/nixos /tmp/nixos
cd /tmp/nixos
```

### Step 2: Check/Update Disk Device

Default is `/dev/sda`. Update if different:

```bash
lsblk

# If needed, edit disko.nix
nvim /tmp/nixos/hosts/poptart/disko.nix
# Change: device = "/dev/nvme0n1";  # or your disk
```

### Step 3: Run Disko

```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko /tmp/nixos/hosts/poptart/disko.nix
```

Creates:
- 512MB EFI partition
- Btrfs root with subvolumes (@, @home, @nix, @log, @snapshots)

### Step 4: Install

```bash
mkdir -p /mnt/etc/nixos
cp -r /tmp/nixos/* /mnt/etc/nixos/

nixos-generate-config --root /mnt --no-filesystems

nixos-install --flake /mnt/etc/nixos#poptart --no-root-passwd
```

### Step 5: Reboot and Configure

```bash
reboot

# Login as: hollywood / changeme
passwd

# Update git config
nvim ~/.config/home-manager/git.nix  # Or rebuild after editing /etc/nixos

# Launch Moonlight to connect to your Sunshine server
moonlight-qt
```

---

## DevShell Commands

```bash
cd /etc/nixos && nix develop

rebuild HOST        # Build and switch
rebuild-boot HOST   # Build for next boot only
rebuild-test HOST   # Test without adding to bootloader
rebuild-dry HOST    # Show what would be built
diff HOST           # Compare current vs new system
update              # Update flake inputs
gc                  # Garbage collect old generations
fmt                 # Format all .nix files
check               # Check flake for errors
```

---

## Troubleshooting

### Disko fails

```bash
# Clean up partial state
cryptsetup close cryptroot0 2>/dev/null || true
cryptsetup close cryptroot1 2>/dev/null || true
wipefs -a /dev/nvme0n1  # or your disk
wipefs -a /dev/nvme1n1

# Retry disko
```

### Boot fails after install

```bash
# Boot from USB, unlock and mount manually
cryptsetup open /dev/nvme0n1p2 cryptroot0
cryptsetup open /dev/nvme1n1p2 cryptroot1
mount -o subvol=@rootfs /dev/mapper/cryptroot0 /mnt
mount -o subvol=@nix /dev/mapper/cryptroot0 /mnt/nix
mount /dev/nvme0n1p1 /mnt/boot/efi
nixos-install --flake /mnt/etc/nixos#toaster
```

### VFIO not binding GPU

```bash
# Check IOMMU enabled
dmesg | grep -i iommu

# Check vfio-pci loaded
lsmod | grep vfio

# Verify GPU IDs match
lspci -nn | grep -i nvidia
cat /etc/nixos/hosts/toaster/vars.nix | grep vfioIds
```

### Btrfs RAID degraded (one drive failed)

```bash
# System boots automatically in degraded mode
sudo btrfs device stats /  # Check which drive failed

# Replace drive:
# 1. Shutdown, swap drive
# 2. Boot (degraded)
# 3. Partition new drive like old one
# 4. Add to RAID: sudo btrfs device add /dev/nvmeXn1p2 /
# 5. Rebalance: sudo btrfs balance start /
```

---

## File Structure

```
/etc/nixos/
├── flake.nix                    # Flake definition
├── flake.lock                   # Pinned versions
├── hosts/
│   ├── toaster/
│   │   ├── default.nix          # Host config
│   │   ├── disko.nix            # Disk layout
│   │   └── vars.nix             # Host variables
│   ├── honeypot/
│   │   ├── default.nix
│   │   ├── disko.nix
│   │   └── vars.nix
│   └── poptart/
│       ├── default.nix
│       ├── disko.nix
│       └── vars.nix
├── users/
│   ├── draxel/
│   │   ├── default.nix          # User system config
│   │   └── home/                # Home-manager config
│   │       ├── default.nix
│   │       └── git.nix
│   ├── bamse/
│   │   ├── default.nix
│   │   └── home/
│   │       ├── default.nix
│   │       ├── git.nix
│   │       └── pentest.nix
│   └── hollywood/
│       ├── default.nix
│       └── home/
│           ├── default.nix
│           └── git.nix
├── modules/
│   ├── nixos/
│   │   ├── core/                # Always-imported system modules
│   │   └── features/            # Optional system features
│   │       ├── desktop/
│   │       ├── hardware/
│   │       ├── networking/
│   │       ├── services/
│   │       └── virtualization/
│   └── home/
│       ├── core/                # Always-imported home modules
│       └── programs/            # Optional home programs
├── secrets/
│   └── secrets.yml
└── docs/
    ├── install.md               # This file
    └── design.md
```
