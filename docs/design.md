

## Hardware

### Motherboard - ASUS ROG Strix B850-I Gaming WIFI
- **Form Factor:** Mini-ITX
- **Chipset:** AMD B850 | **Socket:** AM5 (LGA 1718)
- **Memory:** 2x DDR5 DIMM slots, up to 128GB, AMD EXPO support
- **Storage:** 2x M.2 PCIe 5.0 x4 slots, 2x SATA 6Gb/s
- **Expansion:** 1x PCIe 5.0 x16 SafeSlot
- **VRM:** 10+2+1 power stages (70A per stage)
- **Connectivity:** Wi-Fi 7 (2.9Gbps), Bluetooth 5.4, Intel 2.5Gb LAN
- **Audio:** SupremeFX 7.1 (ALC4080), 32-bit/384kHz

### Processor - AMD Ryzen 7 9800X3D
- **Cores/Threads:** 8 cores / 16 threads
- **Architecture:** Zen 5 (Granite Ridge) | **Process:** 4nm
- **Base Clock:** 4.7 GHz | **Boost Clock:** 5.2 GHz
- **Cache:** 8MB L2 + 96MB L3 (3D V-Cache) = 104MB total
- **TDP:** 120W | **Socket:** AM5
- **Features:** PCIe 5.0, DDR5-5600 native, unlocked multiplier, AVX-512

### Memory - Kingston FURY Beast 64GB (2x32GB) DDR5-6000
- **Speed:** 6000MT/s | **Latency:** CL30-36-36 (10ns)
- **Voltage:** 1.4V
- **Profiles:** Intel XMP 3.0 + AMD EXPO 1.0
- **Features:** On-die ECC, dual 32-bit subchannels

### Power Supply - Corsair SF1000 Platinum ATX 3.1
- **Wattage:** 1000W | **Efficiency:** 80 PLUS Platinum (92% @ 50% load)
- **Form Factor:** SFX (100mm x 125mm x 63.5mm), ATX bracket included
- **Standards:** ATX 3.1, PCIe 5.1 compliant
- **Connectors:** Fully modular, native 12VHPWR cable included
- **Cooling:** 92mm PWM fan with zero-RPM mode
- **Warranty:** 7 years

### Graphics Card - MSI GeForce RTX 5070 Ti 16GB Inspire 3X OC
- **GPU:** NVIDIA Blackwell 2.0 (5nm) | **CUDA Cores:** 8960
- **Tensor Cores:** 280 (4th Gen) | **RT Cores:** 70 (3rd Gen)
- **Base Clock:** 2295 MHz | **Boost Clock:** 2482 MHz (2497 MHz Extreme)
- **Memory:** 16GB GDDR7, 256-bit, 28 Gbps, 896 GB/s bandwidth
- **TDP:** 300W | **Connector:** 1x 16-pin 12VHPWR
- **Outputs:** 3x DisplayPort 2.1b, 1x HDMI 2.1b
- **Dimensions:** 288mm x 112mm x 50mm (triple-fan)

### Storage - Samsung 9100 PRO M.2 NVMe Gen5 2TB x2
- **Interface:** PCIe Gen 5.0 x4 | **Protocol:** NVMe 2.0
- **Sequential Read:** 14,700 MB/s | **Sequential Write:** 13,400 MB/s
- **Random IOPS:** 2,200K read / 2,600K write
- **Controller:** Samsung Presto (5nm) | **NAND:** V8 236-layer TLC
- **Cache:** 2GB LPDDR4X per drive
- **Endurance:** 1,200 TBW | **Warranty:** 5 years
- **Form Factor:** M.2 2280 (single-sided, 2.38mm thick)

---

## System Architecture

### Overview
NixOS hypervisor with NVIDIA GPU passthrough, Btrfs RAID 1 for data redundancy, and modular VM management for penetration testing workflows.

### Key Design Decisions

#### GPU Strategy: Boot-Time Selection
- **Host Display:** AMD Radeon Graphics (integrated in 9800X3D) - always available
- **RTX 5070 Ti:** Shared between host and VMs via boot menu selection

**Use Cases:**
| Boot Mode | RTX 5070 Ti | Use Case |
|-----------|-------------|----------|
| Default | nvidia driver | Ollama, Docker GPU workloads, CUDA dev |
| VFIO | vfio-pci | Windows gaming, hashcat cracking |

**How It Works:**
- **NixOS specializations** create two boot entries in systemd-boot
- Select "VFIO" boot entry when you want to game in Windows VM
- Select default boot entry for host GPU work (Ollama, Docker)
- Reboot to switch modes (~30 seconds)

**Why Boot Selection (not runtime switching):**
- More stable than unloading/reloading drivers at runtime
- Clean driver state on every switch
- Boot menu makes intent explicit
- NixOS-idiomatic approach

#### Storage Architecture: Btrfs RAID 1

**Why RAID 1 over split drives:**
- Single drive failure = zero data loss
- 2TB usable (not 4TB, but data safety > capacity for pentest work)
- Btrfs handles RAID natively with scrubbing and self-healing
- Your NixOS config is reproducible anyway; it's your `/home` and `/work` that matter

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                           Btrfs RAID 1 Pool                                  │
│                    (nvme0n1p2 + nvme1n1p2 mirrored via LUKS)                 │
├──────────────────────────────────────────────────────────────────────────────┤
│  Subvolume     │ Mount Point        │ Options              │ Snapshot │ Notes│
├────────────────┼────────────────────┼──────────────────────┼──────────┼──────┤
│  @rootfs       │ /                  │ compress=zstd,noatime│ Weekly   │ [1]  │
│  @nix          │ /nix               │ compress=zstd,noatime│ No       │ [2]  │
│  @persist      │ /persist           │ compress=zstd,noatime│ Daily    │ [3]  │
│  @home         │ /home              │ compress=zstd,noatime│ Hourly   │ [4]  │
│  @work         │ /work              │ compress=zstd,noatime│ Hourly   │ [4]  │
│  @libvirt      │ /var/lib/libvirt   │ nodatacow,noatime    │ No       │ [5]  │
│  @log          │ /var/log           │ nodatacow,noatime    │ No       │ [6]  │
│  @cache        │ /var/cache         │ compress=zstd,noatime│ No       │ [7]  │
│  @tmp          │ /var/tmp           │ nodatacow,noatime    │ No       │ [8]  │
│  @snapshots    │ /.snapshots        │ compress=zstd,noatime│ -        │ [9]  │
└────────────────┴────────────────────┴──────────────────────┴──────────┴──────┘

Notes:
[1] Root - reproducible via NixOS, weekly snapshots for rollback (wiped on boot with impermanence)
[2] Nix store - fully reproducible, no snapshots needed
[3] Impermanence persist - state that survives reboots
[4] CRITICAL data - most frequent snapshots, longest retention
[5] VM images: nodatacow prevents qcow2 fragmentation, no snapshots (VMs rebuildable)
[6] Logs: high write, nodatacow reduces fragmentation
[7] Package cache: exclude from snapshots
[8] Persistent temp: /tmp is tmpfs (RAM), this is /var/tmp
[9] Snapshot storage - never snapshot this one
```

**Mount Options:**
| Option | Purpose |
|--------|---------|
| `compress=zstd` | ~30% space savings, minimal CPU overhead |
| `noatime` | No access time updates, reduces SSD writes |
| `nodatacow` | Disables CoW - required for VM images, logs, temp |
| `ssd,space_cache=v2` | Auto-applied, optimizes for NVMe |

#### Encryption Strategy

**Recommended: LUKS2 + TPM2 + PIN**
```
┌──────────────────────────────────────────────────────┐
│  LUKS2 Encrypted Container (both NVMe drives)        │
│  ├─ Unlock Method: TPM2 + PIN (systemd-cryptenroll)  │
│  ├─ Fallback: Recovery key (store offline!)          │
│  └─ Contains: Btrfs RAID 1 filesystem                │
└──────────────────────────────────────────────────────┘
```

**TPM Recommendation: Yes, but with caveats**
- Use TPM2 + PIN (not TPM-only) - prevents evil maid attacks
- Store recovery keys in multiple secure offline locations
- If motherboard dies without recovery key = data loss
- As a pentester, you understand the trade-offs

**AMD SME (Secure Memory Encryption):**
```nix
boot.kernelParams = [
  "amd_iommu=on"
  "iommu=pt"
  "mem_encrypt=on"  # AMD SME - encrypts RAM contents
];
```
- Protects against cold boot attacks and physical memory dumps
- Minimal performance impact (~1-2%)
- Hardware-accelerated AES encryption of all RAM

**Partition Layout (per drive):**
```
nvme0n1 / nvme1n1:
├─ p1: 1GB   EFI System Partition (FAT32, mirrored manually)
└─ p2: Rest  LUKS2 container → Btrfs RAID 1 member
```
Note: With systemd-boot, /boot lives on the EFI partition - no separate boot partition needed.

---

### Virtualization Architecture

#### Libvirt/QEMU/KVM Setup

**IOMMU Groups (Critical for GPU passthrough):**
- Enable AMD-Vi/IOMMU in BIOS
- Kernel params: `amd_iommu=on iommu=pt`
- Verify GPU is in isolated IOMMU group (Mini-ITX usually good)

**VFIO Configuration Module:**

This module uses NixOS specializations to provide two boot options:
- **Default boot:** GPU on host (nvidia driver) - for Ollama, Docker, CUDA dev
- **VFIO boot:** GPU isolated for VM passthrough - for gaming, hashcat

```nix
# modules/vfio.nix
let
  # RTX 5070 Ti (update these after running lspci -nn | grep -i nvidia)
  gpuIDs = [
    "10de:XXXX" # Graphics (find with lspci -nn | grep VGA)
    "10de:XXXX" # Audio (find with lspci -nn | grep Audio | grep -i nvidia)
  ];
in { pkgs, lib, config, ... }: {
  options.vfio.enable = with lib;
    mkEnableOption "Configure the machine for VFIO GPU passthrough";

  config = let cfg = config.vfio;
  in {
    boot = {
      initrd.kernelModules = [
        "vfio_pci"
        "vfio"
        "vfio_iommu_type1"

        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];

      kernelModules = [ "kvm-amd" ];
      blacklistedKernelModules = [ "nouveau" ];

      kernelParams = [
        "amd_iommu=on"
        "iommu=pt"
        "mem_encrypt=on"  # AMD SME
      ] ++ lib.optional cfg.enable
        # When VFIO enabled, isolate GPU at boot
        ("vfio-pci.ids=" + lib.concatStringsSep "," gpuIDs);
    };

    # NVIDIA drivers (only used when vfio.enable = false)
    hardware.nvidia = {
      modesetting.enable = true;
      open = true;  # RTX 50 series uses open kernel modules
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
    };
    hardware.nvidia-container-toolkit.enable = true;

    # Graphics and USB passthrough
    hardware.graphics.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;
  };
}
```

**Boot Specialization (in configuration.nix):**
```nix
# Two boot entries: default (GPU on host) and VFIO (GPU for VM)
specialisation."VFIO".configuration = {
  system.nixos.tags = [ "with-vfio" ];
  vfio.enable = true;
};
```

**How it works:**
1. **Default boot:** nvidia modules load first, GPU available on host
2. **VFIO boot:** `vfio-pci.ids` kernel param claims GPU before nvidia can
3. Select boot option in systemd-boot menu

**Find your GPU IDs after install:**
```bash
lspci -nn | grep -i nvidia
# Example output:
# 01:00.0 VGA compatible controller [0300]: NVIDIA Corporation [10de:2782] (rev a1)
# 01:00.1 Audio device [0403]: NVIDIA Corporation [10de:22bc] (rev a1)
# The IDs are 10de:2782 and 10de:22bc
```

**Why specializations over runtime switching:**
- Cleaner, more NixOS-idiomatic approach
- No fragile driver unload/reload scripts
- Boot menu makes intent explicit
- More stable GPU handoff

#### VM Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                    VM Templates                             │
├─────────────────────────────────────────────────────────────┤
│  Template          │ Purpose           │ GPU  │ Resources   │
├────────────────────┼───────────────────┼──────┼─────────────┤
│  windows-gaming    │ Gaming, daily use │ Yes  │ 6C/32GB+GPU │
│  kali-base         │ Standard pentest  │ No   │ 4C/8GB      │
│  kali-gpu          │ Hash cracking     │ Yes  │ 4C/16GB+GPU │
│  windows-11        │ AD/Client testing │ Yes  │ 4C/16GB+GPU │
│  windows-server    │ AD lab            │ No   │ 2C/8GB      │
│  parrot-base       │ Alternative tools │ No   │ 4C/8GB      │
│  remnux            │ Malware analysis  │ No   │ 2C/4GB      │
└────────────────────┴───────────────────┴──────┴─────────────┘
```

**Windows Gaming VM Optimizations:**
- CPU pinning (isolcpus for dedicated cores)
- Hugepages (1GB pages for memory performance)
- virtio drivers for disk/network
- Looking Glass for low-latency display
- Evdev passthrough for keyboard/mouse
- Scream for low-latency audio

```nix
# Hugepages for VM performance (32GB for gaming VM)
boot.kernelParams = [
  "hugepagesz=1G"
  "hugepages=32"
  "default_hugepagesz=1G"
];
```

#### Looking Glass Setup

Looking Glass captures the GPU framebuffer directly, providing near-native gaming latency without HDMI cable switching.

**NixOS Configuration:**
```nix
# Looking Glass client and dependencies
environment.systemPackages = with pkgs; [
  looking-glass-client
];

# KVMFR kernel module (optional, better performance than IVSHMEM)
boot.extraModulePackages = with config.boot.kernelPackages; [ kvmfr ];
boot.kernelModules = [ "kvmfr" ];

# Shared memory device permissions
systemd.tmpfiles.rules = [
  "f /dev/shm/looking-glass 0660 draxel libvirtd -"
];

# KVMFR device permissions (if using kvmfr module)
services.udev.extraRules = ''
  SUBSYSTEM=="kvmfr", OWNER="draxel", GROUP="libvirtd", MODE="0660"
'';
```

**Windows VM XML Additions:**
```xml
<!-- Looking Glass shared memory (add to <devices> section) -->
<shmem name='looking-glass'>
  <model type='ivshmem-plain'/>
  <size unit='M'>128</size>  <!-- 128MB for 4K, 64MB for 1440p, 32MB for 1080p -->
</shmem>
```

**Windows Setup:**
1. Download Looking Glass Host from https://looking-glass.io
2. Install the host application in Windows
3. Configure to start automatically

**Launch Looking Glass:**
```bash
# Basic usage
looking-glass-client

# Fullscreen with spice clipboard
looking-glass-client -F -m 97  # 97 = Right Ctrl to release mouse

# With audio passthrough disabled (use Scream instead)
looking-glass-client -F -m 97 -a
```

#### Scream Audio (Low-Latency VM Audio)

Scream provides low-latency audio streaming from Windows VM to host.

**NixOS Configuration:**
```nix
environment.systemPackages = with pkgs; [ scream ];

# Systemd user service for Scream receiver (uses PipeWire on GNOME)
systemd.user.services.scream = {
  description = "Scream audio receiver";
  wantedBy = [ "graphical-session.target" ];
  after = [ "pipewire.service" ];
  serviceConfig = {
    ExecStart = "${pkgs.scream}/bin/scream -i virbr0 -o pipewire";
    Restart = "always";
    RestartSec = "5";
  };
};
```

**Windows Setup:**
1. Download Scream from https://github.com/duncanthrax/scream/releases
2. Run `Install-Scream.bat` as Administrator
3. Reboot Windows
4. Set "Scream (WDM)" as default audio device in Windows Sound settings

#### Evdev Input Passthrough

Share keyboard/mouse between host and VM with hotkey switching - no USB passthrough needed.

**VM XML Configuration:**
```xml
<!-- Add to Windows VM XML (find your devices with: ls /dev/input/by-id/) -->
<input type='evdev'>
  <source dev='/dev/input/by-id/usb-YOUR_KEYBOARD-event-kbd' grab='all' repeat='on' grabToggle='ctrl-ctrl'/>
</input>
<input type='evdev'>
  <source dev='/dev/input/by-id/usb-YOUR_MOUSE-event-mouse' grab='all' grabToggle='ctrl-ctrl'/>
</input>

<!-- Remove default tablet/mouse if present -->
<!-- <input type='tablet' bus='usb'/> -->
```

**Usage:**
- Double-tap **Left Ctrl** to switch input between host and VM
- Works seamlessly with Looking Glass
- No USB passthrough overhead

**Find your input devices:**
```bash
ls -la /dev/input/by-id/
# Look for *-event-kbd and *-event-mouse
```

**Engagement Workflow:**
1. Clone template → engagement-specific VM
2. Snapshot before each major phase
3. Work files mounted from host `/work/{client}`
4. Network isolation via libvirt networks
5. Post-engagement: archive VM, wipe clone

#### Shared Folder Strategy

```nix
# Virtio-fs for high-performance host→VM sharing
# Mount /work/{engagement} into VMs as needed
# Read-only templates, read-write for active work
```

**Directory Structure:**
```
/work/
├── clients/
│   ├── {client-a}/
│   │   ├── scope.txt
│   │   ├── notes/
│   │   ├── evidence/
│   │   └── reports/
│   └── {client-b}/
├── templates/
│   └── report-templates/
└── tools/
    └── custom-scripts/
```

#### USB Device Passthrough

```nix
# Udev rules for USB device permissions (passthrough to VMs)
services.udev.extraRules = ''
  # Xbox controllers
  SUBSYSTEM=="usb", ATTR{idVendor}=="045e", MODE="0666"
  # PlayStation controllers
  SUBSYSTEM=="usb", ATTR{idVendor}=="054c", MODE="0666"
  # Nintendo controllers
  SUBSYSTEM=="usb", ATTR{idVendor}=="057e", MODE="0666"
  # YubiKey
  SUBSYSTEM=="usb", ATTR{idVendor}=="1050", MODE="0666"
  # Generic USB storage (careful with this)
  # SUBSYSTEM=="usb", ATTR{idVendor}=="XXXX", MODE="0666"
'';

# Add user to input group for evdev passthrough
users.users.draxel.extraGroups = [ "input" ];
```

**Passing USB to VMs:**
1. Open virt-manager → VM → Add Hardware → USB Host Device
2. Select device to pass through
3. For persistent passthrough, add to VM XML:
```xml
<hostdev mode='subsystem' type='usb' managed='yes'>
  <source>
    <vendor id='0x045e'/>  <!-- Xbox -->
    <product id='0x0b12'/> <!-- Controller model -->
  </source>
</hostdev>
```

**Find USB vendor/product IDs:**
```bash
lsusb
# Bus 001 Device 003: ID 045e:0b12 Microsoft Corp. Xbox Controller
```

---

### Host Desktop Environment (GNOME)

```nix
# GNOME + GDM with Wayland (integrated AMD graphics)
services.xserver.enable = true;
services.xserver.displayManager.gdm.enable = true;
services.xserver.desktopManager.gnome.enable = true;

# AMD integrated graphics (for host display while NVIDIA is in VM)
hardware.graphics.enable = true;

# Remove bloat (optional)
environment.gnome.excludePackages = with pkgs; [
  gnome-tour gnome-music epiphany geary
];

# Virt-manager GUI for libvirt
programs.virt-manager.enable = true;

# Useful GNOME extensions
environment.systemPackages = with pkgs; [
  gnome-extension-manager
  gnomeExtensions.appindicator
  gnomeExtensions.dash-to-dock
];
```

**Why GNOME for this setup:**
- Native Wayland (uses integrated AMD GPU, leaves NVIDIA free)
- virt-manager integrates well
- Good Tailscale/VPN indicators
- Solid multi-monitor support for when GPU is in host mode

---

### Container Services (Docker on Host)

#### Docker + NVIDIA Container Toolkit
```nix
virtualisation.docker = {
  enable = true;
  storageDriver = "btrfs";  # Native btrfs support
};
hardware.nvidia-container-toolkit.enable = true;  # GPU passthrough to containers
```

**Ready for future services:**
- Ollama (LLM inference)
- Portainer, Traefik, etc.
- Any GPU-accelerated containers

#### Docker Data Location
```
/opt/docker/              # Compose files (future)
/var/lib/docker/          # Docker storage (on btrfs)
```

---

### Network Architecture

#### Tailscale Integration
```nix
services.tailscale.enable = true;
services.tailscale.useRoutingFeatures = "both";  # Exit node + subnet router
```

**Use Cases:**
- Remote access to hypervisor
- Subnet routing for VM lab access
- Exit node for VMs if needed

#### Network Bridge (LAN Gaming/Direct Access)

Bridge gives VMs a real IP on your LAN - required for LAN multiplayer, game streaming, etc.

```nix
# Bridge for VMs needing direct LAN access
networking.bridges.br0.interfaces = [ "enp6s0" ];  # Your ethernet interface
networking.interfaces.br0.useDHCP = true;

# Keep NetworkManager managing wifi, but exclude bridged interface
networking.networkmanager.unmanaged = [ "enp6s0" "br0" ];

# Alternative: If using only ethernet (no wifi)
# networking.useDHCP = false;
# networking.bridges.br0.interfaces = [ "enp6s0" ];
# networking.interfaces.br0.useDHCP = true;
```

**Find your ethernet interface:**
```bash
ip link show
# Look for something like enp6s0, enp0s25, eth0
```

**Use in VM:**
1. virt-manager → VM → NIC → Network source: "Bridge device" → br0
2. Or in VM XML: `<interface type='bridge'><source bridge='br0'/></interface>`

#### Libvirt Networks
```
┌─────────────────────────────────────────────────────────────┐
│  Network          │ Purpose              │ Internet Access  │
├───────────────────┼──────────────────────┼──────────────────┤
│  default (NAT)    │ General VMs          │ Yes (NAT)        │
│  br0 (bridge)     │ LAN gaming, streaming│ Yes (real LAN IP)│
│  isolated         │ Malware analysis     │ No               │
│  lab              │ AD lab environment   │ Controlled       │
│  engagement       │ Client simulations   │ Via Tailscale    │
└───────────────────┴──────────────────────┴──────────────────┘
```

---

### Snapshot & Backup Strategy

#### Automated Btrfs Snapshots (btrbk)

```nix
services.btrbk = {
  instances = {
    # Hourly snapshots for critical user data
    local = {
      onCalendar = "hourly";
      settings = {
        timestamp_format = "long";
        snapshot_preserve_min = "2d";
        snapshot_preserve = "24h 7d 4w";  # Conservative retention

        volume."/" = {
          subvolume = {
            home = {
              snapshot_dir = "/.snapshots/home";
            };
            work = {
              snapshot_dir = "/.snapshots/work";
              # Longer retention for client engagements
              snapshot_preserve = "48h 14d 8w";
            };
          };
        };
      };
    };

    # Weekly snapshots for root (reproducible via NixOS)
    system = {
      onCalendar = "weekly";
      settings = {
        timestamp_format = "long";
        snapshot_preserve_min = "7d";
        snapshot_preserve = "4w";

        volume."/" = {
          subvolume."" = {  # @rootfs
            snapshot_dir = "/.snapshots/rootfs";
          };
        };
      };
    };
  };
};

# NOTE: @libvirt is NOT snapshotted - VMs are rebuildable and snapshots
# of large disk images waste significant space. Use VM-level snapshots
# in virt-manager if needed for specific VMs.
```

**Create snapshot directories during install:**
```bash
mkdir -p /.snapshots/{home,work,rootfs}
```

**Snapshot Schedule:**
| Subvolume | Frequency | Retention | Rationale |
|-----------|-----------|-----------|-----------|
| @home     | Hourly    | 24h, 7d, 4w | User data, configs, dotfiles |
| @work     | Hourly    | 48h, 14d, 8w | Engagements - longest retention |
| @rootfs   | Weekly    | 4w | Root is reproducible via NixOS |
| @libvirt  | -         | - | VMs are rebuildable, use virt-manager snapshots |
| @nix      | -         | - | Fully reproducible, skip |
| @log      | -         | - | Logs rotate themselves |
| @cache    | -         | - | Rebuildable cache |
| @tmp      | -         | - | Temporary by definition |

#### Off-site Backup (Recommended)
- Btrfs send/receive to external drive
- Or: restic/borg to cloud (encrypted)
- Critical for true disaster recovery (fire, theft, both drives fail)

---

### NixOS Garbage Collection & Generations

Keep the Nix store clean and limit boot menu clutter:

```nix
# Automatic garbage collection
nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 14d";
};

# Optimize store (deduplication)
nix.settings.auto-optimise-store = true;

# Limit generations in boot menu
boot.loader.systemd-boot.configurationLimit = 10;

# Enable flakes
nix.settings.experimental-features = [ "nix-command" "flakes" ];

# Allow unfree packages (NVIDIA drivers)
nixpkgs.config.allowUnfree = true;
```

**Manual cleanup commands:**
```bash
# List all generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Delete generations older than 7 days
sudo nix-collect-garbage --delete-older-than 7d

# Delete all but current generation (careful!)
sudo nix-collect-garbage -d

# Optimize store manually
nix-store --optimise
```

---

### NixOS Module Structure

```
/etc/nixos/
├── flake.nix                 # Flake entry point (disko, impermanence)
├── disko-config.nix          # Declarative disk layout
├── configuration.nix         # Main config (imports below)
└── modules/
    ├── vfio.nix              # VFIO/GPU passthrough with specializations
    ├── virtualization.nix    # Libvirt, QEMU, Docker, Looking Glass, Scream
    ├── networking.nix        # Tailscale, bridges, firewall
    ├── users.nix             # User accounts (draxel)
    ├── desktop.nix           # GNOME + GDM
    ├── snapshots.nix         # btrbk config
    └── impermanence.nix      # Ephemeral root (Phase 2)
```

Note: With disko, `hardware-configuration.nix` and `filesystem.nix` are replaced by `disko-config.nix`.

---

### Disko Configuration (Declarative Disk Layout)

Disko handles all disk partitioning, encryption, and filesystem setup declaratively. No manual `parted`, `cryptsetup`, or `mkfs` commands needed.

#### flake.nix

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, disko, impermanence, ... }: {
    nixosConfigurations.toaster = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        impermanence.nixosModules.impermanence
        ./disko-config.nix
        ./configuration.nix
      ];
    };
  };
}
```

#### disko-config.nix

```nix
# Declarative disk layout: 2x NVMe, LUKS2, Btrfs RAID 1, 10 subvolumes
{
  disko.devices = {
    disk = {
      nvme0 = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/efi";
                mountOptions = [ "fmask=0022" "dmask=0022" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot0";
                settings = {
                  allowDiscards = true;
                };
                # Interactive password prompt during disko run
                # For automated installs, use: passwordFile = "/tmp/disk-password";
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "-L" "nixos"
                    "-d" "raid1"
                    "-m" "raid1"
                    "/dev/mapper/cryptroot1"  # Second LUKS device joins RAID
                  ];
                  subvolumes = {
                    "@rootfs" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "@persist" = {
                      mountpoint = "/persist";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "@work" = {
                      mountpoint = "/work";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "@libvirt" = {
                      mountpoint = "/var/lib/libvirt";
                      mountOptions = [ "nodatacow" "noatime" ];
                    };
                    "@log" = {
                      mountpoint = "/var/log";
                      mountOptions = [ "nodatacow" "noatime" ];
                    };
                    "@cache" = {
                      mountpoint = "/var/cache";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "@tmp" = {
                      mountpoint = "/var/tmp";
                      mountOptions = [ "nodatacow" "noatime" ];
                    };
                    "@snapshots" = {
                      mountpoint = "/.snapshots";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                  };
                };
              };
            };
          };
        };
      };
      nvme1 = {
        type = "disk";
        device = "/dev/nvme1n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                # Second EFI for redundancy - not mounted by default
                # Manually sync with: rsync -av /boot/efi/ /mnt/efi2/
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot1";
                settings = {
                  allowDiscards = true;
                };
                # This LUKS device joins the RAID via nvme0's extraArgs
                # No content here - it's part of the btrfs raid1 defined above
              };
            };
          };
        };
      };
    };
  };
}
```

**Important Notes:**
- Disko handles LUKS password prompts interactively during install
- Both drives use the **same passphrase** (you'll be prompted twice)
- The second drive's LUKS partition joins the RAID via `extraArgs`
- `nodatacow` subvolumes (@libvirt, @log, @tmp) disable copy-on-write for VM images and logs

---

### Installation Checklist

1. [ ] Boot NixOS ISO
2. [ ] Clone/create flake with disko-config.nix and configuration.nix
3. [ ] Run disko to partition, encrypt, and mount (one command!)
4. [ ] Install NixOS with `nixos-install --flake`
5. [ ] Reboot and verify system boots
6. [ ] Find GPU PCI IDs and update vfio.nix
7. [ ] Enroll TPM2 + PIN with systemd-cryptenroll
8. [ ] Add recovery keys and store offline
9. [ ] Enable Tailscale
10. [ ] Set up VM templates (Windows gaming, Kali)
11. [ ] Test VFIO boot specialization
12. [ ] Test failover (simulate drive removal in degraded mode)
13. [ ] (Phase 2) Enable impermanence after stable

---

### Installation Guide (Disko)

#### Prerequisites
- NixOS minimal ISO on USB (latest unstable recommended for RTX 50 series)
- Both NVMe drives installed
- Network connection (for downloading packages)
- Your NixOS flake ready (GitHub repo or local files)

#### Step 1: Boot and Prepare Environment
```bash
# Boot from NixOS USB, login as root (no password)

# Connect to wifi if needed
nmcli device wifi connect "SSID" password "password"
# Or use ethernet (auto-connects)

# Verify drives are detected
lsblk
# Should see nvme0n1 and nvme1n1 (both ~2TB)

# Enable flakes in the live environment
export NIX_CONFIG="experimental-features = nix-command flakes"
```

#### Step 2: Create Your Flake

**Option A: Clone from your repo (recommended)**
```bash
# If you've already pushed your config to GitHub
git clone https://github.com/draxel/nixos-config /tmp/nixos
cd /tmp/nixos
```

**Option B: Create files manually**
```bash
mkdir -p /tmp/nixos
cd /tmp/nixos

# Create flake.nix (copy from Disko Configuration section above)
nano flake.nix

# Create disko-config.nix (copy from Disko Configuration section above)
nano disko-config.nix

# Create configuration.nix (see Step 3)
nano configuration.nix
```

#### Step 3: configuration.nix

```nix
# /tmp/nixos/configuration.nix
{ config, pkgs, lib, ... }:

{
  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.systemd-boot.configurationLimit = 10;

  # Kernel - IOMMU, VFIO, KVM
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "mem_encrypt=on"  # AMD SME
  ];
  boot.initrd.kernelModules = [ "vfio_pci" "vfio" "vfio_iommu_type1" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.blacklistedKernelModules = [ "nouveau" ];

  # Networking
  networking.hostName = "toaster";
  networking.networkmanager.enable = true;

  # Timezone and locale
  time.timeZone = "Europe/Stockholm";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  # Desktop (GNOME + Wayland on AMD iGPU)
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  hardware.graphics.enable = true;

  # User account
  users.users.draxel = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "libvirtd" "docker" "input" "kvm" ];
    initialPassword = "changeme";  # Change on first login!
  };

  # Essential packages
  environment.systemPackages = with pkgs; [
    neovim git htop wget curl
    pciutils usbutils lm_sensors
    looking-glass-client
    scream
  ];

  # Virtualization
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      ovmf.enable = true;
      ovmf.packages = [ pkgs.OVMFFull.fd ];
      swtpm.enable = true;
    };
  };
  programs.virt-manager.enable = true;

  # Docker
  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
  };

  # NVIDIA (host mode - for Ollama, Docker GPU)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;  # RTX 50 series uses open kernel modules
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };
  hardware.nvidia-container-toolkit.enable = true;

  # Looking Glass shared memory
  systemd.tmpfiles.rules = [
    "f /dev/shm/looking-glass 0660 draxel libvirtd -"
  ];

  # USB passthrough rules
  services.udev.extraRules = ''
    # Xbox controllers
    SUBSYSTEM=="usb", ATTR{idVendor}=="045e", MODE="0666"
    # PlayStation controllers
    SUBSYSTEM=="usb", ATTR{idVendor}=="054c", MODE="0666"
    # YubiKey
    SUBSYSTEM=="usb", ATTR{idVendor}=="1050", MODE="0666"
  '';

  # Tailscale
  services.tailscale.enable = true;

  # SSH (for remote access during setup)
  services.openssh.enable = true;

  # Firewall
  networking.firewall.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nixpkgs.config.allowUnfree = true;

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  system.stateVersion = "25.11";
}
```

#### Step 4: Run Disko (Partitioning + Encryption + Mounting)

```bash
cd /tmp/nixos

# This single command does EVERYTHING:
# - Partitions both drives
# - Creates LUKS containers (prompts for password twice - use SAME password!)
# - Creates Btrfs RAID 1
# - Creates all 10 subvolumes
# - Mounts everything to /mnt
nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko \
  ./disko-config.nix

# Verify everything is mounted correctly
mount | grep /mnt
df -h /mnt
btrfs filesystem show

# Create snapshot directories for btrbk
mkdir -p /mnt/.snapshots/{home,work,rootfs}

# Create /work directory structure
mkdir -p /mnt/work/{clients,templates,tools}
```

**What just happened:**
- Both drives partitioned with GPT (1GB EFI + rest LUKS)
- Both LUKS containers created and opened
- Btrfs RAID 1 created across both LUKS devices
- All 10 subvolumes created with correct mount options
- Everything mounted to /mnt ready for install

#### Step 5: Install NixOS

```bash
cd /tmp/nixos

# Copy your flake to the mounted system
mkdir -p /mnt/etc/nixos
cp -r ./* /mnt/etc/nixos/

# Install NixOS using the flake
nixos-install --flake /mnt/etc/nixos#toaster --no-root-passwd

# Reboot
reboot
```

**Note:** `--no-root-passwd` skips root password since you have sudo via draxel user.

#### Step 6: Post-Install Setup
```bash
# After reboot, login as your user

# Change your password
passwd

# Authenticate Tailscale
sudo tailscale up

# Check RAID status
sudo btrfs filesystem show
sudo btrfs device stats /

# Get GPU PCI addresses for passthrough scripts
lspci | grep -i nvidia
# Note the addresses (e.g., 01:00.0, 01:00.1)

# Verify IOMMU groups
for d in /sys/kernel/iommu_groups/*/devices/*; do
  n=${d#*/iommu_groups/*}; n=${n%%/*}
  printf 'IOMMU Group %s ' "$n"
  lspci -nns "${d##*/}"
done | grep -i nvidia
```

#### Step 7: Enroll TPM2 (Optional, do after stable boot)
```bash
# First, ensure system boots reliably without TPM

# Then enroll TPM2 + PIN
sudo systemd-cryptenroll /dev/nvme0n1p2 --tpm2-device=auto --tpm2-with-pin=yes
sudo systemd-cryptenroll /dev/nvme1n1p2 --tpm2-device=auto --tpm2-with-pin=yes

# Add recovery key (SAVE THIS OFFLINE!)
sudo systemd-cryptenroll /dev/nvme0n1p2 --recovery-key
sudo systemd-cryptenroll /dev/nvme1n1p2 --recovery-key

# Update NixOS config to use TPM
# Add to boot.initrd.luks.devices.cryptroot0/1:
#   crypttabExtraOpts = [ "tpm2-device=auto" ];
```

#### Quick Reference Commands
```bash
# Check Btrfs RAID health
sudo btrfs filesystem show
sudo btrfs device stats /

# Scrub (run monthly)
sudo btrfs scrub start /

# List snapshots
sudo btrfs subvolume list /.snapshots

# Emergency: Mount degraded (if one drive fails)
mount -o degraded,subvol=@rootfs /dev/mapper/cryptroot0 /mnt
```

---

### Impermanence (Ephemeral Root)

Impermanence wipes the root filesystem on every boot - only explicitly declared state persists. This ensures a clean system, prevents malware persistence, and forces you to declaratively manage all state.

**How it works:**
- Root (`@rootfs`) is wiped on every boot (or use tmpfs)
- State that must survive lives in `/persist` (`@persist` subvolume)
- NixOS module creates symlinks/bind mounts from `/persist` to expected locations

**Note:** The flake.nix in the Disko Configuration section already includes impermanence. Just add the module below.

#### Impermanence Configuration

```nix
# modules/impermanence.nix
{ config, pkgs, ... }:

{
  # Wipe root on boot using a blank snapshot
  boot.initrd.postDeviceCommands = pkgs.lib.mkBefore ''
    mkdir -p /mnt
    mount -o subvol=/ /dev/mapper/cryptroot0 /mnt

    # Delete old root, restore blank snapshot
    btrfs subvolume delete /mnt/@rootfs 2>/dev/null || true
    btrfs subvolume snapshot /mnt/@rootfs-blank /mnt/@rootfs

    umount /mnt
  '';

  # Persist critical system state
  environment.persistence."/persist" = {
    hideMounts = true;

    # System directories that must persist
    directories = [
      "/etc/nixos"                    # NixOS config
      "/etc/NetworkManager/system-connections"  # WiFi passwords
      "/var/lib/libvirt"              # VM configs (also on @libvirt)
      "/var/lib/docker"               # Docker data
      "/var/lib/tailscale"            # Tailscale state
      "/var/lib/bluetooth"            # Bluetooth pairings
      "/var/lib/systemd/coredump"     # Core dumps
      "/var/lib/systemd/timers"       # Timer state
    ];

    # System files that must persist
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];

    # User-specific persistence (for draxel)
    users.draxel = {
      directories = [
        ".config"             # App configs (includes GNOME settings)
        ".local/share"        # App data
        ".local/state"        # App state
        ".cache"              # Caches (optional, can skip for truly clean boots)
        ".gnupg"              # GPG keys
        ".ssh"                # SSH keys and config
        ".mozilla"            # Firefox profile
        "Documents"
        "Downloads"
        "Pictures"
        "Projects"
      ];
      files = [
        ".bash_history"
        ".zsh_history"
      ];
    };
  };
}
```

#### Installation Changes for Impermanence

**Additional subvolume during install:**
```bash
# After creating other subvolumes, create @persist and blank snapshot
btrfs subvolume create /mnt/@persist

# Create blank rootfs snapshot (for reset on boot)
btrfs subvolume snapshot -r /mnt/@rootfs /mnt/@rootfs-blank
```

**Mount @persist:**
```bash
mkdir -p /mnt/persist
mount -o subvol=@persist,$OPTS /dev/mapper/cryptroot0 /mnt/persist
```

**Update installation checklist:**
- Create 10 subvolumes (add @persist)
- Create @rootfs-blank snapshot after initial install
- Verify impermanence module loads correctly

#### Why Impermanence?

| Benefit | Description |
|---------|-------------|
| Clean boots | System always starts from known state |
| No cruft accumulation | Temp files, broken configs auto-cleaned |
| Malware persistence | Rootkits can't survive reboot |
| Forced declarative config | Must explicitly declare all state |
| Easy rollback | Just reboot to clean state |

**Trade-offs:**
- Steeper learning curve
- Must remember to persist new state
- Slightly longer boot (snapshot restore)
- Debugging harder (logs can be lost if not persisted)

**Recommendation:** Get the base system working first, then add impermanence as a Phase 2 enhancement once you're comfortable with NixOS.

---

### Security Considerations

- **Secure Boot:** Optional but recommended (requires signing NixOS with lanzaboote)
- **AMD SME:** Enabled - encrypts RAM contents against cold boot attacks
- **Firewall:** Default deny, allow only Tailscale + specific services
- **Host Minimal:** Keep host lean - heavy work happens in VMs
- **Engagement Isolation:** Each client in separate VM, separate network
- **Evidence Integrity:** Snapshots before/after evidence collection
- **Impermanence:** Root wiped on boot - malware cannot persist

---

### Troubleshooting

#### Installation Issues

**"No root device found" on boot:**
- LUKS UUIDs in configuration.nix don't match actual devices
- Fix: Boot live USB, run `blkid /dev/nvme0n1p2` and verify UUIDs match config

**"Failed to mount /nix" or other subvolumes:**
- Subvolume names wrong or hardware-configuration.nix incomplete
- Fix: Verify hardware-configuration.nix has all 10 fileSystems entries

**NVIDIA driver fails to load:**
- RTX 50 series may need latest unstable NixOS
- Fix: Use `nixos-unstable` channel or add nvidia-open overlay

**Boot hangs at LUKS prompt:**
- Both drives need same passphrase and both must unlock
- Fix: Ensure cryptroot0 AND cryptroot1 are configured in boot.initrd.luks.devices

#### Post-Install Issues

**GDM won't start / black screen:**
- NVIDIA driver conflict with Wayland
- Fix: Ensure `hardware.graphics.enable = true` and `services.xserver.videoDrivers = [ "nvidia" ]`

**VM won't start - "IOMMU not found":**
- IOMMU not enabled in BIOS or kernel
- Fix: Enable AMD-Vi/IOMMU in BIOS, verify with `dmesg | grep -i iommu`

**GPU passthrough fails:**
- GPU not in isolated IOMMU group
- Fix: Check IOMMU groups script in post-install, may need ACS override patch

**Btrfs degraded mode warning:**
- One drive offline in RAID 1
- Fix: Check `btrfs device stats /`, replace failed drive, run `btrfs balance`

**TPM enrollment fails:**
- TPM2 not enabled in BIOS or not detected
- Fix: Enable TPM in BIOS, verify with `systemd-cryptenroll --tpm2-device=list`

#### Quick Fixes

```bash
# Rebuild after config changes
sudo nixos-rebuild switch

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Boot previous generation from systemd-boot menu
# Press Space during boot → select older generation

# Check system logs
journalctl -b -p err

# Check NVIDIA driver status
nvidia-smi

# Verify libvirtd is running
systemctl status libvirtd

# Manual Btrfs scrub (data integrity check)
sudo btrfs scrub start /
sudo btrfs scrub status /
```