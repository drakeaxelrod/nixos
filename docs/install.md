# NixOS Installation Guide

Installation guide for **toaster** - AMD Ryzen 9800X3D + RTX 5070 Ti gaming/pentesting workstation.

## Hardware Summary

| Component | Model |
|-----------|-------|
| CPU | AMD Ryzen 7 9800X3D (8C/16T, 3D V-Cache) |
| GPU | NVIDIA RTX 5070 Ti (for VFIO passthrough + host CUDA) |
| RAM | 64GB DDR5-6000 (2x32GB, AMD EXPO) |
| Storage | 2x Samsung 990 PRO 2TB NVMe (Btrfs RAID 1) |
| Motherboard | ASUS ROG Strix B850-I Gaming WiFi (Mini-ITX) |

## Prerequisites

- [ ] NixOS minimal ISO on USB ([download latest unstable](https://nixos.org/download))
- [ ] Both NVMe drives installed
- [ ] Network connection (ethernet recommended, WiFi works)
- [ ] This repo pushed to GitHub (or files on USB)
- [ ] Strong LUKS passphrase ready (same for both drives)

---

## Phase 1: Base Installation

### Step 1: Boot and Prepare

```bash
# Boot NixOS USB, login as root (no password needed)

# Connect to network
# Ethernet auto-connects, for WiFi:
nmcli device wifi connect "YOUR_SSID" password "YOUR_PASSWORD"

# Verify both drives detected
lsblk
# Should see: nvme0n1, nvme1n1 (both ~2TB)

# Enable flakes
export NIX_CONFIG="experimental-features = nix-command flakes"
```

### Step 2: Clone Config

```bash
# Clone your config repo
git clone https://github.com/YOUR_USER/nixos /tmp/nixos
cd /tmp/nixos

# Verify files exist
ls -la
# Should see: flake.nix, disko.nix, configuration.nix, vars.nix, home/
```

### Step 3: Run Disko (Partitioning + Encryption)

This single command does everything:
- Partitions both NVMe drives (1GB EFI + LUKS)
- Creates LUKS2 containers (you'll be prompted for password TWICE - use SAME password!)
- Creates Btrfs RAID 1 across both encrypted devices
- Creates all 10 subvolumes with correct mount options
- Mounts everything to /mnt

```bash
cd /tmp/nixos

# Run disko - DESTRUCTIVE! Wipes both drives!
nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko \
  ./disko.nix

# You'll be prompted for LUKS password twice (once per drive)
# USE THE SAME PASSWORD FOR BOTH!
```

### Step 4: Verify Disk Setup

```bash
# Check mounts
mount | grep /mnt
# Should see: /, /nix, /home, /work, /persist, /var/lib/libvirt, etc.

# Check Btrfs RAID
btrfs filesystem show
# Should show: raid1 with both devices, Label: 'nixos'

# Check subvolumes
btrfs subvolume list /mnt
# Should see: @rootfs, @nix, @home, @work, @persist, @libvirt, @log, @cache, @tmp, @snapshots
```

### Step 5: Create Required Directories

```bash
# Snapshot directories for btrbk
mkdir -p /mnt/.snapshots/{home,work,rootfs,libvirt}

# Work directory structure
mkdir -p /mnt/work/{clients,templates,tools}

# Set ownership (will be fixed after install, but helps)
chmod 755 /mnt/work
```

### Step 6: Install NixOS

```bash
cd /tmp/nixos

# Copy flake to target system
mkdir -p /mnt/etc/nixos
cp -r ./* /mnt/etc/nixos/

# Install NixOS
nixos-install --flake /mnt/etc/nixos#toaster --no-root-passwd

# This takes 10-30 minutes depending on network speed
# --no-root-passwd: We use sudo via draxel user instead
```

### Step 7: Reboot

```bash
reboot
```

Remove USB when prompted. System will boot to LUKS password prompt.

---

## Phase 2: Post-Install Configuration

### Step 1: First Login

```bash
# Login as: draxel
# Password: changeme

# Immediately change password!
passwd

# Verify system basics
neofetch  # or just check you're in GNOME
```

### Step 2: Update vars.nix

```bash
cd /etc/nixos

# Find your network interface name
ip link
# Look for something like: enp6s0, enp7s0, etc.

# Edit vars.nix
sudo nvim vars.nix
# Update: network.bridge.interface = "enp6s0";  # Your actual interface
```

### Step 3: Find GPU PCI IDs (for VFIO)

```bash
# Get NVIDIA GPU IDs
lspci -nn | grep -i nvidia
# Example output:
# 01:00.0 VGA compatible controller [0300]: NVIDIA Corporation [10de:2782] (rev a1)
# 01:00.1 Audio device [0403]: NVIDIA Corporation [10de:22bc] (rev a1)

# The IDs are: 10de:2782 (GPU) and 10de:22bc (Audio)

# Edit vars.nix
sudo nvim vars.nix
# Update gpu.vfioIds:
#   vfioIds = [
#     "10de:2782"  # RTX 5070 Ti GPU
#     "10de:22bc"  # RTX 5070 Ti Audio
#   ];
```

### Step 4: Verify IOMMU Groups

```bash
# Check GPU is in its own IOMMU group (required for passthrough)
for d in /sys/kernel/iommu_groups/*/devices/*; do
  n=${d#*/iommu_groups/*}; n=${n%%/*}
  printf 'IOMMU Group %s ' "$n"
  lspci -nns "${d##*/}"
done | grep -i nvidia

# Both GPU and Audio should be in the SAME group
# and ideally ONLY those two devices in that group
```

### Step 5: Rebuild with Updates

```bash
cd /etc/nixos

# Enter dev shell for nice commands
nix develop

# Rebuild with your changes
rebuild

# Or without devshell:
sudo nixos-rebuild switch --flake ".#toaster" --fast -j 8 --cores 2
```

### Step 6: Enable Tailscale

```bash
sudo tailscale up

# Follow the auth URL printed
# Optionally enable as exit node:
sudo tailscale up --advertise-exit-node
```

### Step 7: Verify Everything

```bash
# Check Btrfs RAID health
sudo btrfs filesystem show
sudo btrfs device stats /
# Should show 0 errors

# Check services
systemctl status libvirtd
systemctl status docker
systemctl status tailscaled

# Check NVIDIA driver
nvidia-smi
# Should show RTX 5070 Ti

# Check Looking Glass shared memory
ls -la /dev/shm/looking-glass
```

---

## Phase 3: TPM2 Enrollment (Optional)

Only do this after system boots reliably for a few days!

### Step 1: Enroll TPM2 + PIN

```bash
# Enroll TPM with PIN for both drives
sudo systemd-cryptenroll /dev/nvme0n1p2 --tpm2-device=auto --tpm2-with-pin=yes
sudo systemd-cryptenroll /dev/nvme1n1p2 --tpm2-device=auto --tpm2-with-pin=yes

# You'll set a PIN (can be same as LUKS password or different)
```

### Step 2: Generate Recovery Keys

```bash
# SAVE THESE OFFLINE! Print them, store in safe.
sudo systemd-cryptenroll /dev/nvme0n1p2 --recovery-key
sudo systemd-cryptenroll /dev/nvme1n1p2 --recovery-key

# Recovery keys look like: 5xnzq-s2n4h-... (64 chars)
```

### Step 3: Test TPM Unlock

```bash
# Reboot and verify TPM+PIN unlocks both drives
reboot

# At boot, enter PIN (not full LUKS passphrase)
# If it fails, recovery key or original passphrase still work
```

---

## Phase 4: VFIO Testing

### Test Default Boot (GPU on Host)

```bash
# Default boot entry uses NVIDIA on host
nvidia-smi
# Should show GPU

# Docker GPU access
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
```

### Test VFIO Boot (GPU for VM)

```bash
# Reboot, select "NixOS - VFIO" in boot menu
# (or: sudo nixos-rebuild boot --specialisation VFIO && reboot)

# After boot, GPU should NOT be available on host
nvidia-smi
# Should fail or show no devices

# Check VFIO binding
lspci -nnk | grep -A3 -i nvidia
# Should show: Kernel driver in use: vfio-pci
```

---

## Quick Reference

### DevShell Commands

```bash
cd /etc/nixos
nix develop

# Available commands:
rebuild        # nixos-rebuild switch (fast, parallel)
rebuild-boot   # Build for next boot only
rebuild-test   # Test without adding to bootloader
rebuild-dry    # Show what would be built
diff           # Compare current vs new system
update         # Update flake inputs
gc             # Garbage collect old generations
fmt            # Format all .nix files
check          # Check flake for errors
```

### Btrfs Commands

```bash
# RAID health
sudo btrfs filesystem show
sudo btrfs device stats /

# Manual scrub
sudo btrfs scrub start /
sudo btrfs scrub status /

# List snapshots
sudo btrfs subvolume list /.snapshots

# Emergency: Mount degraded (if one drive fails)
mount -o degraded,subvol=@rootfs /dev/mapper/cryptroot0 /mnt
```

### VM Management

```bash
# Start virt-manager GUI
virt-manager

# List VMs
virsh list --all

# Start/stop VM
virsh start windows-gaming
virsh shutdown windows-gaming
```

---

## Troubleshooting

### Boot fails after disko

```bash
# Boot from USB again, unlock and mount manually:
cryptsetup open /dev/nvme0n1p2 cryptroot0
cryptsetup open /dev/nvme1n1p2 cryptroot1
mount -o subvol=@rootfs /dev/mapper/cryptroot0 /mnt
mount -o subvol=@nix /dev/mapper/cryptroot0 /mnt/nix
# ... mount other subvolumes
nixos-install --flake /mnt/etc/nixos#toaster
```

### NVIDIA driver issues

```bash
# Check if nouveau is blacklisted
lsmod | grep nouveau  # Should be empty

# Check NVIDIA module
lsmod | grep nvidia

# Rebuild with latest driver
sudo nixos-rebuild switch --upgrade
```

### VFIO not binding GPU

```bash
# Check IOMMU enabled
dmesg | grep -i iommu

# Check vfio-pci loaded
lsmod | grep vfio

# Verify GPU IDs in vars.nix match lspci output
lspci -nn | grep -i nvidia
```

### One drive failed

```bash
# System boots degraded automatically
# Check which drive failed:
sudo btrfs device stats /

# Replace drive procedure:
# 1. Shutdown, replace failed drive
# 2. Boot (will be degraded)
# 3. Partition new drive same as old
# 4. Add to RAID: sudo btrfs device add /dev/nvme1n1p2 /
# 5. Rebalance: sudo btrfs balance start /
```

---

## File Structure

```
/etc/nixos/
├── flake.nix           # Flake with all inputs
├── flake.lock          # Pinned versions
├── disko.nix           # Disk layout (LUKS + Btrfs RAID)
├── configuration.nix   # Main system config
├── vars.nix            # Customizable variables (edit this!)
├── home/
│   └── draxel.nix      # Home-manager config
├── modules/            # Future: split configs
├── secrets/
│   └── secrets.yaml.example
└── docs/
    └── install.md      # This file
```

## Next Steps

After stable install:

1. [ ] Set up Windows gaming VM with GPU passthrough
2. [ ] Configure Looking Glass for low-latency VM display
3. [ ] Set up Kali Linux VM for pentesting
4. [ ] Enable bridge networking for VMs (`vars.nix`: `network.bridge.enable = true`)
5. [ ] (Phase 2) Enable impermanence for ephemeral root
6. [ ] (Phase 2) Enable sops-nix for secrets management
