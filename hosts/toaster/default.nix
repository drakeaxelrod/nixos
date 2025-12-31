# Toaster - Gaming + Pentesting Workstation
#
# Hardware: AMD Ryzen 7 7800X3D, NVIDIA RTX 5070 Ti, 64GB DDR5, 2x 2TB NVMe
# Features: VFIO GPU passthrough, Looking Glass, Impermanence
#
# Boot Menu (Limine):
#   - NixOS           → Host GPU mode (NVIDIA on host for gaming/CUDA)
#   - NixOS [vfio]    → VFIO mode (GPU isolated for Windows VM)
#
{ config, lib, pkgs, inputs, meta, modules, ... }:

let
  # Helper to get specific users from meta.users
  # Usage: users.draxel or users.all
  users = lib.genAttrs meta.users (name: name) // {
    all = meta.users;
  };
in

{
  imports = [
    ./disko.nix

    # Import-based pattern: explicitly import only needed modules

    # Desktop environment
    modules.nixos.desktop.display.gdm
    modules.nixos.desktop.managers.gnome

    # Hardware
    modules.nixos.hardware.amd
    modules.nixos.hardware.nvidia
    modules.nixos.hardware.audio

    # Networking
    modules.nixos.networking.tailscale

    # Services
    modules.nixos.services.openssh
    modules.nixos.services.btrbk

    # Virtualization
    modules.nixos.virtualization.libvirt
    modules.nixos.virtualization.docker

    # VFIO - granular imports
    modules.nixos.vfio.dualBoot      # Provides dualBoot option + auto-imports core
    modules.nixos.vfio.lookingGlass
    modules.nixos.vfio.scream

    # VMs
    modules.nixos.vms

    # Security
    modules.nixos.security.sops
  ];

  # ==========================================================================
  # System Identity
  # ==========================================================================
  # Derived from mkHost - no need to set here
  # networking.hostName = meta.hostname;      # "toaster"
  # system.stateVersion = meta.stateVersion;  # "25.11"

  # ==========================================================================
  # Bootloader - Limine for clean boot menu
  # ==========================================================================

  modules.system.boot = {
    loader = "limine";     # Modern, stylish bootloader
    maxGenerations = 10;    # Keep boot menu clean
    timeout = 5;           # 5 second timeout
  };

  # ==========================================================================
  # Hardware Features
  # ==========================================================================

  # AMD CPU and iGPU (Radeon 780M)
  modules.hardware.amd.enable = true;

  # NVIDIA RTX 5070 Ti (discrete GPU)
  modules.hardware.nvidia = {
    enable = true;
    enableWayland = true;
    enableSuspendSupport = true;
    powerManagement.enable = true;

    # PRIME configuration for hybrid graphics (AMD iGPU + NVIDIA dGPU)
    prime = {
      enable = true;
      mode = "offload";  # On-demand NVIDIA rendering
      amdBusId = "PCI:13:0:0";    # AMD 780M iGPU (0d:00.0)
      nvidiaBusId = "PCI:1:0:0";  # NVIDIA RTX 5070 Ti (01:00.0)
    };
  };

  # Audio
  modules.hardware.audio.enable = true;

  # ==========================================================================
  # GPU Mode (Dual-Boot)
  # ==========================================================================
  # Creates boot entries for switching GPU modes:
  #   - "NixOS - host": GPU available to host (NVIDIA drivers loaded)
  #   - "NixOS - vfio": GPU isolated for VM passthrough
  #
  # PCI IDs are auto-derived from virtualisation.vms GPU settings.

  modules.vfio.dualBoot = {
    enable = true;
    defaultMode = "host";  # "host" or "vfio"
  };
  #
  # # Looking Glass & Scream (active in VFIO mode)
  modules.vfio.lookingGlass = {
    enable = true;
    users = [ users.draxel ];  # Derived from meta.users
  };
  modules.vfio.scream.enable = true;

  # ==========================================================================
  # Virtualization
  # ==========================================================================

  modules.virtualization.libvirt = {
    enable = true;
    users = [ users.draxel ];  # Auto-added to libvirtd group
  };

  modules.virtualization.docker = {
    enable = true;
    users = [ users.draxel ];  # Auto-added to docker group
  };

  # ==========================================================================
  # Desktop Environment
  # ==========================================================================
  # Desktop modules are now imported above (import-based pattern)
  # Configuration is done here through options

  # Enable GNOME desktop
  modules.desktop.gnome.enable = true;

  # Enable GDM with Wayland
  modules.desktop.gdm = {
    enable = true;
    wayland = true;
  };

  # Enable Wayland utilities

  # ==========================================================================
  # Networking
  # ==========================================================================

  # modules.networking.bridge = {
  #   enable = true;
  #   name = "br0";
  #   interface = "eth0";  # PLACEHOLDER - Update with: ip link
  # };

  modules.networking.tailscale.enable = true;

  # ==========================================================================
  # Services
  # ==========================================================================

  modules.services.openssh.enable = true;
  modules.services.btrbk.enable = true;

  # ==========================================================================
  # Impermanence (Ephemeral Root)
  # ==========================================================================

  # Disabled by default - enable after system is stable and @rootfs-blank snapshot exists
  # To enable:
  #   1. Boot system normally and ensure everything works
  #   2. Create blank root snapshot:
  #      sudo mount -o subvol=/ /dev/mapper/cryptroot1 /mnt
  #      sudo btrfs subvolume snapshot -r /mnt/@rootfs /mnt/@rootfs-blank
  #      sudo umount /mnt
  #   3. Set modules.impermanence.enable = true below
  #   4. Rebuild: nx switch
  # modules.impermanence.enable = true;

  # ==========================================================================
  # SOPS Secrets
  # ==========================================================================

  # Disabled by default - enable after setting up age keys
  modules.security.sops.enable = true;

  # ==========================================================================
  # Declarative Virtual Machines
  # ==========================================================================
  # VMs are defined declaratively and auto-registered with libvirt on boot.
  #
  # GPU passthrough settings (pciId, address) are used to auto-derive:
  #   - modules.vfio.gpuPciIds
  #   - modules.vfio.gpuPciAddresses
  #   - modules.vfio.lookingGlass.shmSize
  #
  # VFIO must be explicitly enabled (see dual-boot mode above).
  # The VM is always defined, but GPU passthrough only works in VFIO boot.

  virtualisation.vms.win11 = {
    type = "windows-gaming";
    memory = 32768;           # 32GB RAM
    vcpus = 12;               # Total vCPUs (cores * threads)

    cpu = {
      cores = 6;              # 6 physical cores
      threads = 2;            # 2 threads per core
      pinning = {
        enable = true;        # Pin vCPUs to host CPUs
        startCpu = 4;         # Reserve CPUs 0-3 for host
      };
    };

    hugepages = {
      enable = true;          # Use 1GB hugepages
      count = 32;             # 32 x 1GB = 32GB
    };

    gpu = {
      enable = true;
      # NVIDIA RTX 5070 Ti (GB203)
      pciId = "10de:2c05";           # GPU vendor:device (for VFIO kernel binding)
      audioPciId = "10de:22e9";      # Audio vendor:device
      # PCI addresses from lspci -D
      address = "0000:01:00.0";       # GPU address (for libvirt XML)
      audioAddress = "0000:01:00.1";  # Audio address
    };

    storage = {
      disk = "/var/lib/libvirt/images/win11.qcow2";
      # Uncomment for fresh install:
      # windowsIso = /var/lib/libvirt/images/Win11.iso;
      # virtioIso = /var/lib/libvirt/images/virtio-win.iso;
    };

    network.type = "nat";     # or "bridge" with network.bridge = "br0"
    graphics = "spice";       # "spice", "vnc", or "none"
    lookingGlass.size = 128;  # KVMFR shared memory for 4K
    autostart = false;
  };

  # ==========================================================================
  # Users
  # ==========================================================================
  # Users are defined as self-contained modules in users/ directory
  # and composed in flake.nix via: users = with self.users; [ draxel ];
}
