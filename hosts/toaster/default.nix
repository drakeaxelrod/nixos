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

  # VM definitions for this host
  vms = import ./vms;
in

{
  imports = [
    ./disko.nix

    # Import-based pattern: explicitly import only needed modules

    # System packages (essential CLI tools available before home-manager)
    modules.nixos.system.packages

    # Desktop environment
    modules.nixos.desktop.display.sddm
    modules.nixos.desktop.managers.plasma

    # Gaming
    modules.nixos.gaming.steam
    modules.nixos.gaming.lutris

    # Hardware
    modules.nixos.hardware.amd
    modules.nixos.hardware.nvidia
    modules.nixos.hardware.audio
    modules.nixos.hardware.bluetooth

    # Networking
    modules.nixos.networking.tailscale

    # Services
    modules.nixos.services.openssh
    modules.nixos.services.btrbk
    modules.nixos.services.ollama
    modules.nixos.services.sunshine

    # Virtualization
    modules.nixos.virtualization.libvirt
    modules.nixos.virtualization.docker

    # VFIO - GPU passthrough with specializations
    modules.nixos.vfio.gpuPassthrough
    modules.nixos.vfio.lookingGlass
    modules.nixos.vfio.scream

    # VMs
    modules.nixos.vms
    ./vms

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
    loader = "limine";          # Modern, stylish bootloader
    kernelPackage = "linuxPackages_latest";  # Use latest stable kernel
    maxGenerations = 10;        # Keep boot menu clean
    timeout = 20;                # 5 second timeout

    # Plymouth for graphical LUKS password prompt
    plymouth = {
      enable = true;
      theme = "breeze";      # KDE Breeze theme (modern and clean)
      silentBoot = true;     # Hide kernel messages for cleaner experience
    };
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

    # RTX 50-series (Blackwell) REQUIRES open kernel modules
    openDriver = true;

    # PRIME configuration for hybrid graphics (AMD iGPU + NVIDIA dGPU)
    prime = {
      enable = false;
      mode = "offload";  # On-demand NVIDIA rendering
      amdBusId = "PCI:13:0:0";    # AMD 780M iGPU (0d:00.0)
      nvidiaBusId = "PCI:1:0:0";  # NVIDIA RTX 5070 Ti (01:00.0)
    };
  };

  # Audio
  modules.hardware.audio.enable = true;

  # Bluetooth
  modules.hardware.bluetooth.enable = true;

  # QMK/Vial keyboard support (udev rules for flashing and configuring)
  hardware.keyboard.qmk.enable = true;

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

  # Enable Plasma desktop
  modules.desktop.plasma.enable = true;

  # Enable SDDM with Wayland
  modules.desktop.sddm = {
    enable = true;
    theme = "sddm-astronaut-theme";
    themePackage = pkgs.sddm-astronaut;
    themeConfig = "japanese_aesthetic";  # Theme variant
    wayland = true;
  };

  # ==========================================================================
  # Gaming
  # ==========================================================================

  # Steam includes: Gamescope, GameMode, MangoHud, ProtonUp-Qt, Protontricks
  modules.gaming.steam.enable = true;

  # Lutris includes: Wine Staging, Winetricks, GameMode, MangoHud
  modules.gaming.lutris.enable = true;

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

  # Ollama - Local LLM server (CUDA accelerated)
  modules.services.ollama = {
    enable = true;
    acceleration = "cuda";
    models = [ "llama3.2" ];
  };

  # Sunshine - Game streaming server (use with Moonlight client)
  modules.services.sunshine.enable = true;

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
}
