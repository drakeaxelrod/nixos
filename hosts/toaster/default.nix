# Toaster - Gaming + Pentesting Workstation
#
# Hardware: AMD Ryzen 7 7800X3D, NVIDIA RTX 5070 Ti, 64GB DDR5, 2x 2TB NVMe
# Features: VFIO GPU passthrough, Looking Glass, Impermanence
#
# Boot Menu (Limine):
#   - NixOS           → Host GPU mode (NVIDIA on host for gaming/CUDA)
#   - NixOS [vfio]    → VFIO mode (GPU isolated for Windows VM)
#
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ./disko.nix
  ];

  # ==========================================================================
  # System Identity
  # ==========================================================================

  networking.hostName = "toaster";
  system.stateVersion = "25.11";

  # ==========================================================================
  # Bootloader - Limine for clean boot menu
  # ==========================================================================

  modules.core.boot = {
    loader = "limine";     # Modern, stylish bootloader
    maxGenerations = 5;    # Keep boot menu clean
    timeout = 5;           # 5 second timeout
  };

  # ==========================================================================
  # Hardware Features
  # ==========================================================================

  modules.hardware.amd-cpu.enable = true;
  modules.hardware.amd-gpu.enable = true;

  # ==========================================================================
  # audio
  # ==========================================================================
  
  modules.hardware.audio.enable = true;

  # ==========================================================================
  # GPU Mode (Dual-Boot)
  # ==========================================================================
  # Creates boot entries for switching GPU modes:
  #   - "NixOS - host": GPU available to host (NVIDIA drivers loaded)
  #   - "NixOS - vfio": GPU isolated for VM passthrough
  #
  # PCI IDs are auto-derived from virtualisation.vms GPU settings.

  # modules.vfio.dualBoot = {
  #   enable = true;
  #   defaultMode = "host";  # "host" or "vfio"
  # };
  #
  # # Looking Glass & Scream (active in VFIO mode)
  # modules.vfio.lookingGlass = {
  #   enable = true;
  #   users = [ "draxel" ];
  # };
  # modules.vfio.scream.enable = true;

  # ==========================================================================
  # Virtualization
  # ==========================================================================

  # modules.virtualization.libvirt = {
  #   enable = true;
  #   users = [ "draxel" ];  # Auto-added to libvirtd group
  # };

  # modules.virtualization.docker = {
  #   enable = true;
  #   users = [ "draxel" ];  # Auto-added to docker group
  # };

  # ==========================================================================
  # Desktop Environment
  # ==========================================================================

  modules.desktop.gnome.enable = true;
  modules.desktop.wayland.enable = true;

  # ==========================================================================
  # Networking
  # ==========================================================================

  # modules.networking.bridge = {
  #   enable = true;
  #   name = "br0";
  #   interface = "eth0";  # PLACEHOLDER - Update with: ip link
  # };

  # modules.networking.tailscale.enable = true;

  # ==========================================================================
  # Services
  # ==========================================================================

  modules.services.openssh.enable = true;
  modules.services.btrbk.enable = true;

  # ==========================================================================
  # Impermanence (Ephemeral Root)
  # ==========================================================================

  # Disabled by default - enable after creating @rootfs-blank snapshot
  modules.impermanence = {
    enable = true;
    users = [ "draxel" ];  # Users to persist home directories for
  };

  # ==========================================================================
  # SOPS Secrets
  # ==========================================================================

  # Disabled by default - enable after setting up age keys
  # modules.security.sops.enable = true;

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
  # VFIO must be explicitly enabled (see specialisation above).
  # The VM is always defined, but GPU passthrough only works in VFIO boot.

  # virtualisation.vms.win11 = {
  #   type = "windows-gaming";
  #   memory = 32768;           # 32GB RAM
  #   vcpus = 12;               # Total vCPUs (cores * threads)
  #
  #   cpu = {
  #     cores = 6;              # 6 physical cores
  #     threads = 2;            # 2 threads per core
  #     pinning = {
  #       enable = true;        # Pin vCPUs to host CPUs
  #       startCpu = 4;         # Reserve CPUs 0-3 for host
  #     };
  #   };
  #
  #   hugepages = {
  #     enable = true;          # Use 1GB hugepages
  #     count = 32;             # 32 x 1GB = 32GB
  #   };
  #
  #   gpu = {
  #     enable = true;
  #     # PLACEHOLDER: Run lspci -nn | grep -i nvidia for IDs
  #     pciId = "10de:XXXX";           # GPU vendor:device (for VFIO kernel binding)
  #     audioPciId = "10de:XXXX";      # Audio vendor:device
  #     # PLACEHOLDER: Run lspci -D | grep -i nvidia for addresses
  #     address = "0000:01:00.0";       # GPU address (for libvirt XML)
  #     audioAddress = "0000:01:00.1";  # Audio address
  #   };
  #
  #   storage = {
  #     disk = "/var/lib/libvirt/images/win11.qcow2";
  #     # Uncomment for fresh install:
  #     # windowsIso = /var/lib/libvirt/images/Win11.iso;
  #     # virtioIso = /var/lib/libvirt/images/virtio-win.iso;
  #   };
  #
  #   network.type = "nat";     # or "bridge" with network.bridge = "br0"
  #   graphics = "spice";       # "spice", "vnc", or "none"
  #   lookingGlass.size = 128;  # KVMFR shared memory for 4K
  #   autostart = false;
  # };

  # ==========================================================================
  # Users
  # ==========================================================================
  # Users are defined as self-contained modules in users/ directory
  # and composed in flake.nix via: users = with self.users; [ draxel ];
}
