# GPU Passthrough Guide

This guide covers setting up GPU passthrough for Windows gaming VMs using the `virtualisation.vms` and `modules.vfio` modules.

## Overview

The system supports dual-boot GPU modes:

| Boot Entry | GPU State | Use Case |
|------------|-----------|----------|
| **Host GPU** | NVIDIA drivers loaded | Native gaming, CUDA, compute |
| **VM Passthrough** | GPU isolated (VFIO) | Windows VM with GPU |

## Quick Start

### 1. Discover Your Hardware

```bash
# Get GPU PCI IDs (for VFIO kernel binding)
lspci -nn | grep -i nvidia
# Example output: 01:00.0 VGA [0300]: NVIDIA [10de:2782]
#                 01:00.1 Audio [0403]: NVIDIA [10de:22bc]
# → pciId = "10de:2782", audioPciId = "10de:22bc"

# Get GPU PCI addresses (for libvirt XML)
lspci -D | grep -i nvidia
# Example output: 0000:01:00.0 VGA ...
#                 0000:01:00.1 Audio ...
# → address = "0000:01:00.0", audioAddress = "0000:01:00.1"
```

### 2. Define Your VM

```nix
# hosts/<hostname>/default.nix

virtualisation.vms.win11 = {
  type = "windows-gaming";
  memory = 32768;           # 32GB
  vcpus = 12;

  cpu = {
    cores = 6;
    threads = 2;
    pinning = {
      enable = true;
      startCpu = 4;         # Reserve CPUs 0-3 for host
    };
  };

  hugepages = {
    enable = true;
    count = 32;             # Match memory size
  };

  gpu = {
    enable = true;
    pciId = "10de:2782";           # From lspci -nn
    audioPciId = "10de:22bc";
    address = "0000:01:00.0";       # From lspci -D
    audioAddress = "0000:01:00.1";
  };

  storage.disk = "/var/lib/libvirt/images/win11.qcow2";
  lookingGlass.size = 128;  # 128MB for 4K
};
```

### 3. Enable VFIO Boot Mode

```nix
# Enable dual-boot with specialisation
modules.vfio.dualBoot = {
  enable = true;
  defaultMode = "host";  # or "vfio" to default to passthrough
};

# Configure VFIO settings (applied in VFIO boot)
modules.vfio.lookingGlass = {
  enable = true;
  users = [ "draxel" ];
};
modules.vfio.scream.enable = true;
```

### 4. Rebuild and Reboot

```bash
sudo nixos-rebuild switch --flake .#hostname
reboot
```

Your boot menu will show (example):
```
NixOS 25.05.20250115.abc1234 (Generation 42)        ← default (host GPU)
NixOS 25.05.20250115.abc1234 (Generation 42, vfio)  ← GPU isolated
```

Each entry includes: NixOS version, build date, git revision, generation number, and GPU mode.

## Module Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ virtualisation.vms.<name>                                   │
│   Define VMs with GPU, CPU, memory, storage settings        │
│   GPU settings auto-derive VFIO configuration               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼ (auto-derives)
┌─────────────────────────────────────────────────────────────┐
│ modules.vfio                                                │
│   gpuPciIds, gpuPciAddresses, lookingGlass.shmSize          │
│   (configured automatically from VM definitions)            │
│                                                             │
│   enable = true/false (controls kernel-level isolation)     │
│   dualBoot.* (controls boot entry generation)               │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
     ┌─────────────────┐            ┌─────────────────┐
     │ Host GPU Boot   │            │ VFIO Boot       │
     │ NVIDIA loaded   │            │ GPU isolated    │
     │ vfio.enable=no  │            │ vfio.enable=yes │
     └─────────────────┘            └─────────────────┘
```

## Configuration Reference

### VM Options (`virtualisation.vms.<name>`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `type` | enum | `"windows-gaming"` | VM template: `windows-gaming`, `linux-server` |
| `memory` | int | `8192` | RAM in MB |
| `vcpus` | int | `8` | Total vCPUs (cores × threads) |
| `cpu.cores` | int | `4` | Physical CPU cores |
| `cpu.threads` | int | `2` | Threads per core |
| `cpu.pinning.enable` | bool | `true` | Pin vCPUs to host CPUs |
| `cpu.pinning.startCpu` | int | `4` | First host CPU to use |
| `gpu.enable` | bool | `false` | Enable GPU passthrough |
| `gpu.pciId` | string | `null` | GPU vendor:device ID |
| `gpu.audioPciId` | string | `null` | Audio vendor:device ID |
| `gpu.address` | string | `null` | GPU PCI address |
| `gpu.audioAddress` | string | `null` | Audio PCI address |
| `hugepages.enable` | bool | `false` | Use 1GB hugepages |
| `hugepages.count` | int | `32` | Number of 1GB pages |
| `storage.disk` | path | auto | Path to qcow2 disk |
| `storage.windowsIso` | path | `null` | Windows installer ISO |
| `storage.virtioIso` | path | `null` | VirtIO drivers ISO |
| `network.type` | enum | `"nat"` | `nat`, `bridge`, `macvtap`, `user` |
| `network.bridge` | string | `"br0"` | Bridge name (if type=bridge) |
| `network.interface` | string | `""` | Physical NIC (if type=macvtap) |
| `network.macvtapMode` | enum | `"bridge"` | Macvtap mode (bridge/vepa/private) |
| `graphics` | enum | `"spice"` | `spice`, `vnc`, `none` |
| `lookingGlass.size` | int | `128` | KVMFR shared memory (MB) |
| `autostart` | bool | `false` | Auto-start on boot |

### VFIO Options (`modules.vfio`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Enable GPU isolation |
| `primaryMode` | bool | `true` | GPU always isolated (vs dynamic) |
| `dualBoot.enable` | bool | `false` | Create boot specialisations |
| `dualBoot.defaultMode` | enum | `"host"` | Default boot: `host` or `vfio` |
| `dualBoot.hostLabel` | string | `"host"` | Boot entry tag for host mode |
| `dualBoot.vfioLabel` | string | `"vfio"` | Boot entry tag for VFIO mode |
| `lookingGlass.enable` | bool | `false` | Enable Looking Glass |
| `lookingGlass.users` | list | `[]` | Users with access |
| `lookingGlass.shmSize` | int | `128` | Shared memory size (MB) |
| `scream.enable` | bool | `true` | Enable Scream audio |

## VM Networking

VMs need network access for Windows activation, updates, game launchers, etc.

### Networking Options (Easiest to Hardest)

| Type | VMs get IPs from | Requires rebuild? | VM-to-host? | Best for |
|------|------------------|-------------------|-------------|----------|
| **NAT** | libvirt DHCP | No | Yes | Most users, default |
| **Macvtap** | Your router | No | No* | Same network as host |
| **Bridge** | Your router | Yes | Yes | Full network integration |

*Macvtap bridge mode: VMs can't reach host directly, but can reach everything else.

### 1. NAT (Default) - Works Out of the Box

VMs get IPs from libvirt (192.168.122.x range) and can access internet via NAT.

```nix
# This is the default - no config needed
network.type = "nat";
```

Pros:
- Works immediately, no configuration
- VMs can access internet
- VMs can reach host

Cons:
- VMs not on your LAN (can't access local services by IP)
- VMs not discoverable by other devices

### 2. Macvtap - Same Network, No Rebuild Needed

VMs connect directly to your physical NIC, getting IPs from your router.
**No bridge configuration, no rebuilds when interface names change.**

```nix
network = {
  type = "macvtap";
  interface = "enp6s0";  # Your physical NIC
};
```

Find your interface:
```bash
ip link | grep -E '^[0-9]+:' | grep -v 'lo\|vir\|docker'
```

Pros:
- VMs on same network as host
- No rebuild if interface changes (just edit VM XML)
- No bridge configuration needed

Cons:
- VMs can't talk to host directly (use router to bounce traffic)
- Interface name must be specified per-VM

### 3. Bridge - Full Network Integration

VMs connect through a host bridge, appearing as full LAN members.

```nix
# In host config
modules.networking.bridge = {
  enable = true;
  interface = "enp6s0";
};

# In VM config
network = {
  type = "bridge";
  bridge = "br0";
};
```

Pros:
- VMs can reach host directly
- Full LAN integration

Cons:
- Requires rebuild if interface name changes
- More complex setup

### Runtime Bridge (No Rebuild)

If you need a bridge but don't want to rebuild for interface changes:

```bash
# Create bridge with NetworkManager (no rebuild needed)
nmcli con add type bridge con-name br0 ifname br0
nmcli con add type ethernet con-name br0-port ifname enp6s0 master br0
nmcli con up br0

# Then use bridge in VM config
network = { type = "bridge"; bridge = "br0"; };
```

### Recommended Setup

For most GPU passthrough gaming setups:

1. **NAT** (default) works fine - Windows can activate, Steam/Epic/etc. work
2. **Macvtap** if you need VMs on your LAN (e.g., for local game servers)
3. **Bridge** only if you need VM-to-host communication

## Windows Installation

### First-Time Setup

1. Download Windows 11 ISO from Microsoft
2. Download VirtIO drivers: https://fedorapeople.org/groups/virt/virtio-win/

```bash
# Place ISOs
sudo mkdir -p /var/lib/libvirt/images
sudo mv Win11.iso /var/lib/libvirt/images/
sudo wget -O /var/lib/libvirt/images/virtio-win.iso \
  https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso

# Create disk
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/win11.qcow2 256G
```

3. Add ISOs to VM config:
```nix
storage = {
  disk = "/var/lib/libvirt/images/win11.qcow2";
  windowsIso = /var/lib/libvirt/images/Win11.iso;
  virtioIso = /var/lib/libvirt/images/virtio-win.iso;
};
```

4. Boot into VFIO mode and start VM:
```bash
virsh start win11
```

5. During Windows install, load VirtIO drivers from the second CD-ROM

### Post-Install

1. Remove ISO options from config (rebuild)
2. Install Looking Glass Host in Windows
3. Install Scream (virtual audio) in Windows

## Using the VM

### Start/Stop
```bash
virsh start win11
virsh shutdown win11
virsh destroy win11  # Force stop
```

### Looking Glass
```bash
looking-glass-client -f /dev/shm/looking-glass
```

### Scream Audio
Scream receiver starts automatically as a user service when in VFIO boot.

## Troubleshooting

### Check IOMMU Groups
```bash
for d in /sys/kernel/iommu_groups/*/devices/*; do
  n=$(basename $(dirname $(dirname $d)))
  echo "Group $n: $(lspci -nns $(basename $d))"
done | sort -V
```

GPU and audio should be in the same group, isolated from other devices.

### Verify VFIO Binding
```bash
# In VFIO boot mode
lspci -k | grep -A3 -i nvidia
# Should show: Kernel driver in use: vfio-pci
```

### VM Won't Start
```bash
virsh dumpxml win11  # Check XML
journalctl -u libvirtd  # Check logs
```

### Looking Glass Black Screen
- Ensure Looking Glass Host is running in Windows
- Check shared memory: `ls -la /dev/shm/looking-glass`
- Verify KVMFR module: `lsmod | grep kvmfr`
