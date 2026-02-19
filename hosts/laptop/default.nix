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
    modules.nixos.hardware.intel
    modules.nixos.hardware.nvidia
    modules.nixos.hardware.audio
    modules.nixos.hardware.bluetooth
    modules.nixos.hardware.zmk

    # Networking
    modules.nixos.networking.base
    modules.nixos.networking.tailscale
    modules.nixos.networking.wireguard

    # Services
    modules.nixos.services.openssh
    modules.nixos.services.btrbk
    modules.nixos.services.keybase
    modules.nixos.services.ollama

    modules.nixos.services.flatpak

    # Virtualization
    modules.nixos.virtualization.libvirt
    modules.nixos.virtualization.docker


    # Security
    modules.nixos.security.base
    modules.nixos.security.fido
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
    loader = "limine";          # Use systemd-boot for now (Limine has boot issues)
    efiMountPoint = "/boot/efi";     # ESP mount point
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
  modules.system.environment = {
    enable = true;
    defaultBrowser = "zen-beta";
  };

  # ==========================================================================
  # Hardware
  # ==========================================================================

  # Intel CPU + iGPU (Alder Lake-P with Iris Xe)
  modules.hardware.intel = {
    enable = true;
    cpu.enableHWP = true;      # Intel Hardware P-States for power management
    gpu.enable = true;          # Iris Xe Graphics
    gpu.enableGuC = true;       # Enable GuC firmware for media encode/decode
    gpu.enableHuC = true;       # Enable HuC firmware for HEVC/H.265
  };

  # NVIDIA RTX 3080 Ti Mobile with PRIME offload
  modules.hardware.nvidia = {
    enable = true;
    enableWayland = true;
    enableSuspendSupport = true;
    powerManagement.enable = true;

    # RTX 3080 Ti (Ampere) uses proprietary drivers
    openDriver = false;

    # PRIME configuration for hybrid graphics (Intel iGPU + NVIDIA dGPU)
    prime = {
      enable = true;
      mode = "offload";  # Use Intel by default, NVIDIA on-demand with nvidia-offload command
      intelBusId = "PCI:0:2:0";    # Intel Iris Xe (00:02.0)
      nvidiaBusId = "PCI:1:0:0";   # NVIDIA RTX 3080 Ti (01:00.0)
    };
  };
  modules.hardware.bluetooth.enable = true;
  modules.hardware.audio.enable = true;

  # QMK/Vial keyboard support (udev rules for flashing and configuring)
  hardware.keyboard.qmk.enable = true;

  # ZMK Studio support (udev rules for USB serial access)
  modules.hardware.zmk = {
    enable = true;
    users = [ "draxel" ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    usbutils  # lsusb and other USB utilissties
    qbittorrent  # Torrent client
    #lspci
    gnupg  # GPG for encryption and signing
    qFlipper # Flipper Zero management tool
    # picocom # Minimal dumb-terminal emulation program
    proton-pass # Password manager CLI
    # cryptsetup: Newer versions (2.3.0+) have experimental BitLocker support via sudo cryptsetup open --type=bitlk <device> <name>
    cryptsetup # LUKS management tools
    kdePackages.isoimagewriter # KDE USB/SD card flashing tool
  ];

  hardware.flipperzero.enable = true;

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
  modules.networking.wireguard.enable = true;

  # ==========================================================================
  # Services
  # ==========================================================================

  modules.services.openssh.enable = true;
  programs.ssh.startAgent = true;
  modules.services.btrbk.enable = true;

  # Keybase - Secure messaging and file sharing
  modules.services.keybase = {
    enable = true;
    enableKBFS = true;  # Mount encrypted filesystem at /keybase
    enableGUI = true;   # Install GUI app
  };

  # Ollama - Local LLM server (CUDA accelerated)
  modules.services.ollama = {
    enable = true;
    acceleration = "cuda";
    models = [ "llama3.2" ];
  };

  # ==========================================================================
  # Security
  # ==========================================================================

  # Security modules imported above - configure here
  modules.security.base.enable = true;

  # FIDO2/U2F authentication for login and sudo (YubiKey + Titan Key)
  # To enroll a new key: pamu2fcfg -o pam://$(hostname) -i pam://$(hostname)
  modules.security.fido = {
    enable = true;
    yubikey = true;  # YubiKey-specific packages (ykman, pcscd)
    control = "sufficient";  # Any FIDO key OR password works
    credentials = ''
      draxel:zDW6bkPPMO2HzvLK25Lo9Hh5ljHD4ZpxS0dQ9dG68m1TuEx2Ra+C+n1CCcMrYBIlV6flF9b8TPpmyUyFkR9dXw==,jwuLPNBiJkkkss+HxTn+DNaklliY4Uh+rCNxv6UOJ5zKydEpkI/Nr0JEEwW/49JK2eeKIMAChuylJGG+B36uvQ==,es256,+presence
    '';
    # TODO: Enroll Titan Key on laptop: pamu2fcfg -o pam://laptop -i pam://laptop
    # Then add the credential line above
    services = {
      login = true;
      sudo = true;
      sddm = true;
    };
    ssh = true;  # Enable FIDO2 SSH keys
  };

  # ==========================================================================
  # Appearance
  # ==========================================================================

  modules.appearance.fonts.enable = true;
}
