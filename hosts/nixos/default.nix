# NixOS - Simple Default Configuration
#
# A minimal, clean NixOS configuration for general use.
# Perfect for testing, development, or as a base to customize.

{ config, pkgs, lib, inputs, meta, modules, ... }:

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

    # System packages (essential CLI tools available before home-manager)
    modules.nixos.system.packages

    # Desktop environment
    modules.nixos.desktop.display.sddm
    modules.nixos.desktop.managers.plasma

    # Hardware
    # modules.nixos.hardware.intel
    modules.nixos.hardware.nvidia
    modules.nixos.hardware.audio
    modules.nixos.hardware.bluetooth

    # Networking
    modules.nixos.networking.tailscale

    # Services
    modules.nixos.services.openssh
    modules.nixos.services.btrbk
    modules.nixos.services.ollama

    # Virtualization
    modules.nixos.virtualization.libvirt
    modules.nixos.virtualization.docker
    
   
    # Security
    modules.nixos.security.base
    modules.nixos.security.sops
    
    # Appearance
    modules.nixos.appearance.fonts
  ];

  # ==========================================================================
  # System Identity
  # ==========================================================================
  # Derived from mkHost - no need to set here
  # networking.hostName = meta.hostname;      # "nixos"
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
  # Environment Variables
  # ==========================================================================

  # XDG-compliant environment variables for all users/sessions
  modules.system.environment.enable = true;
 
  # ==========================================================================
  # Hardware
  # ==========================================================================

  # Hardware modules imported above - configure here
  # Import additional hardware modules as needed:
  # modules.nixos.hardware.intel.enable = true;
  modules.hardware.nvidia = {
    enable = true;
    enableWayland = true;
    enableSuspendSupport = true;
    powerManagement.enable = true;

    # RTX 50-series (Blackwell) REQUIRES open kernel modules
    openDriver = true;

    # PRIME configuration for hybrid graphics (AMD iGPU + NVIDIA dGPU)
    # PRIME configuration for hybrid graphics (AMD iGPU + NVIDIA dGPU)
    #prime = {
     # enable = true;
      #mode = "sync";  # Always use NVIDIA for all rendering
     # amdBusId = "PCI:13:0:0";    # AMD 780M iGPU (0d:00.0)
     # nvidiaBusId = "PCI:1:0:0";  # NVIDIA RTX 5070 Ti (01:00.0)
    #};
  };
  modules.hardware.bluetooth.enable = true;
  modules.hardware.audio.enable = true;
  
  # QMK/Vial keyboard support (udev rules for flashing and configuring)
  hardware.keyboard.qmk.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    usbutils  # lsusb and other USB utilities
    qbittorrent  # Torrent client
    #lspci
  ];
 
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
    # theme = "sddm-astronaut-theme";
    # themePackage = pkgs.sddm-astronaut;
    # themeConfig = "onedark_custom";  # Theme variant
    theme = "breeze";  # Default Breeze theme
    wallpaper = "${inputs.self}/assets/wallpapers/nix-wallpaper-binary-red_8k.png";
    wayland = true;
  };

  # ==========================================================================
  # Networking
  # ==========================================================================

  # Import additional networking modules as needed:
  modules.networking.tailscale.enable = true;

  # ==========================================================================
  # Services
  # ==========================================================================

  modules.services.openssh.enable = true;
  modules.services.btrbk.enable = true;

  # Ollama - Local LLM server (CUDA accelerated)
  # modules.services.ollama = {
  #   enable = true;
  #   acceleration = "cuda";
  #   models = [ "llama3.2" ];
  # };

  # ==========================================================================
  # Security
  # ==========================================================================

  # Security modules imported above - configure here
  modules.security.base.enable = true;

  # ==========================================================================
  # Appearance
  # ==========================================================================

  modules.appearance.fonts.enable = true;
}
