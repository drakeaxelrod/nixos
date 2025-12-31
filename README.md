# NixOS Configuration - Toaster

Modular NixOS configuration for a VFIO-optimized gaming/pentesting workstation.

## Hardware

- **CPU:** AMD Ryzen 7 7800X3D
- **GPU:** NVIDIA RTX 5070 Ti (passed to Windows VM)
- **iGPU:** AMD Radeon 780M (host display)
- **Motherboard:** ASUS ROG Strix B850-I
- **RAM:** 64GB DDR5
- **Storage:** 2x 2TB NVMe M.2 (Btrfs RAID1 + LUKS2)

## Features

- **VFIO GPU passthrough** with dual-boot support (host GPU / VM passthrough)
- **Declarative VMs** - NixOS-native libvirt VM definitions
- **Looking Glass** + Scream for low-latency VM display/audio
- **Impermanence** - ephemeral root filesystem
- **SOPS** secrets management
- **Btrfs** snapshots with btrbk

---

## Remote Installation (From GitHub Flake)

Install directly from the GitHub flake using `nixos-anywhere`. No need to clone the repo on the target machine.

### Prerequisites

- Target machine booted from [NixOS minimal ISO](https://nixos.org/download)
- Both machines on the same network
- `nixos-anywhere` on your local machine

### Step 1: Boot Target Machine from NixOS ISO

1. Download the NixOS minimal ISO
2. Flash to USB: `dd if=nixos-minimal.iso of=/dev/sdX bs=4M status=progress`
3. Boot target machine from USB

### Step 2: Enable SSH on Target

On the **target machine** console:

```bash
# Set password for nixos user
passwd
# Enter: install

# Get IP address
ip addr show
# Note the IP (e.g., 192.168.1.100)
```

### Step 3: Install with nixos-anywhere

On your **local machine**:

```bash
# Install nixos-anywhere if you don't have it
nix-shell -p nixos-anywhere

# Run the installation directly from GitHub
nixos-anywhere \
  --flake github:DrakeAxelrod/nixos#toaster \
  --disk-encryption-keys /tmp/cryptkey <(echo -n "YOUR_LUKS_PASSPHRASE") \
  nixos@192.168.1.100
```

**Or with SSH key:**

```bash
nixos-anywhere \
  --flake github:DrakeAxelrod/nixos#toaster \
  --disk-encryption-keys /tmp/cryptkey <(echo -n "YOUR_LUKS_PASSPHRASE") \
  --ssh-option "IdentityFile=/path/to/your/key" \
  nixos@192.168.1.100
```

This will:
1. SSH into the target
2. Run disko to partition disks with LUKS encryption
3. Install NixOS from your GitHub flake
4. Reboot automatically

### Step 4: First Boot

1. Enter LUKS passphrase at boot prompt
2. Login as `draxel` with password `changeme`
3. Change your password: `passwd`

### Step 5: Update Hardware-Specific Values

After first boot, discover and update hardware values:

```bash
# SSH into the new system
ssh draxel@192.168.1.100

# Discover GPU PCI IDs
lspci -nn | grep -i nvidia
# Example: 01:00.0 VGA [0300]: NVIDIA [10de:2782]
# Example: 01:00.1 Audio [0403]: NVIDIA [10de:22bc]

# Discover network interface
ip link
# Example: enp6s0

# Clone config for local editing
git clone https://github.com/DrakeAxelrod/nixos.git ~/.config/nixos
cd ~/.config/nixos

# Update hosts/toaster/default.nix with real values:
vim hosts/toaster/default.nix
```

Update the VM configuration with your GPU values:
```nix
# In virtualisation.vms.win11.gpu:
gpu = {
  enable = true;
  pciId = "10de:2782";           # From lspci -nn
  audioPciId = "10de:22bc";
  address = "0000:01:00.0";       # From lspci -D
  audioAddress = "0000:01:00.1";
};

# Enable dual-boot
modules.vfio.dualBoot.enable = true;

# Optional: bridge networking
modules.networking.bridge.interface = "enp6s0";  # Your actual interface
```

See [docs/gpu-passthrough.md](docs/gpu-passthrough.md) for full setup guide.

Rebuild:
```bash
sudo nixos-rebuild switch --flake ~/.config/nixos#toaster
```

---

## Alternative: Manual Remote Installation

If you prefer manual control or nixos-anywhere isn't working:

### Step 1: SSH into Target

```bash
ssh nixos@192.168.1.100
sudo -i
```

### Step 2: Partition with Disko (from GitHub)

```bash
# Run disko directly from GitHub flake
nix run github:DrakeAxelrod/nixos#disko -- \
  --mode disko \
  github:DrakeAxelrod/nixos#nixosConfigurations.toaster.config.disko.devices

# Or simpler - fetch and run the disko config
nix-shell -p git
git clone https://github.com/DrakeAxelrod/nixos.git /tmp/nixos
nix run github:nix-community/disko -- --mode disko /tmp/nixos/hosts/toaster/disko.nix
```

Enter LUKS passphrase when prompted (same for both disks).

### Step 3: Install NixOS (from GitHub)

```bash
# Install directly from GitHub flake
nixos-install --flake github:DrakeAxelrod/nixos#toaster --no-root-passwd
```

### Step 4: Reboot

```bash
reboot
```

---

## Post-Installation Setup

### Enable Impermanence

After first successful boot, create the blank root snapshot:

```bash
# Mount btrfs root
sudo mount -o subvol=/ /dev/mapper/cryptroot1 /mnt

# Create blank snapshot
sudo btrfs subvolume snapshot -r /mnt/@rootfs /mnt/@rootfs-blank

# Unmount
sudo umount /mnt

# Enable in config
vim ~/.config/nixos/hosts/toaster/default.nix
# Uncomment: modules.impermanence.enable = true;

# Rebuild
sudo nixos-rebuild switch --flake ~/.config/nixos#toaster
```

### Setup SOPS Secrets

```bash
# Generate age key
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# Show public key (add to .sops.yaml)
age-keygen -y ~/.config/sops/age/keys.txt

# Copy to persist directory
sudo mkdir -p /persist/etc/sops/age
sudo cp ~/.config/sops/age/keys.txt /persist/etc/sops/age/

# Enable in config
# Uncomment: modules.security.sops.enable = true;
```

### Setup Windows 11 VM

```bash
# Create images directory
sudo mkdir -p /var/lib/libvirt/images

# Download VirtIO drivers
sudo wget -O /var/lib/libvirt/images/virtio-win.iso \
  https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso

# Download Windows 11 ISO from Microsoft and place at:
# /var/lib/libvirt/images/Win11.iso

# Create VM disk
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/win11.qcow2 256G

# Start VM (auto-defined on boot)
virsh start win11

# Connect with Looking Glass (after installing host app in Windows)
looking-glass-client -f /dev/shm/looking-glass
```

---

## Development Commands

```bash
cd ~/.config/nixos
nix develop

# Commands (unified nx tool):
nx                 # Show help
nx switch          # Rebuild and switch (toaster)
nx switch laptop   # Rebuild and switch (laptop)
nx boot            # Rebuild for next boot
nx test            # Test without boot entry
nx dry             # Dry run
nx build           # Build without activating
nx update          # Update flake inputs
nx diff            # Show system diff
nx gc              # Garbage collect
nx fmt             # Format nix files
nx check           # Check flake

# Other commands:
sops-edit          # Edit secrets
discover-hardware  # Show GPU/network info
```

---

## Quick Reference

### Rebuild from GitHub (after changes pushed)

```bash
sudo nixos-rebuild switch --flake github:DrakeAxelrod/nixos#toaster
```

### Rebuild from Local

```bash
sudo nixos-rebuild switch --flake ~/.config/nixos#toaster
# Or using devshell:
nx switch
```

### Check IOMMU Groups

```bash
for d in /sys/kernel/iommu_groups/*/devices/*; do
  n=$(basename $(dirname $(dirname $d)))
  echo "Group $n: $(lspci -nns $(basename $d))"
done | sort -V
```

---

## Directory Structure

```
nixos/
├── flake.nix                 # Main entry point
├── docs/                     # Documentation
│   └── gpu-passthrough.md    # VFIO/VM setup guide
├── lib/                      # Custom library functions
│   ├── default.nix           # mkHost helper
│   └── libvirt.nix           # Declarative VM XML generation
├── hosts/toaster/            # Host-specific config
│   ├── default.nix           # Main host config
│   ├── hardware.nix          # Hardware docs
│   └── disko.nix             # Disk partitioning
├── users/                    # Self-contained user modules
│   └── draxel/               # NixOS user + Home Manager
│       ├── default.nix       # User module entry point
│       └── home/             # Home Manager config
├── modules/                  # Reusable modules
│   ├── core/                 # Boot, nix, locale, users
│   ├── hardware/             # CPU, GPU, storage
│   ├── vfio/                 # GPU passthrough + dual-boot
│   ├── virtualization/       # libvirt, docker
│   ├── vms/                  # Declarative VM definitions
│   ├── desktop/              # GNOME, Wayland
│   ├── networking/           # Bridge, Tailscale
│   ├── services/             # SSH, btrbk
│   ├── security/             # SOPS
│   └── impermanence/         # Ephemeral root
└── secrets/                  # Encrypted secrets
```
