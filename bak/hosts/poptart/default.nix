# NixOS configuration for poptart - barebones developer machine
#
# Simple development workstation with Docker and Moonlight

{ config, pkgs, lib, vars, inputs, ... }:

{
  imports = [
    # Disk layout
    ./disko.nix

    # Core modules (always imported)
    ../../modules/nixos/core

    # Feature modules
    ../../modules/nixos/features/desktop/gnome.nix
    ../../modules/nixos/features/hardware/audio.nix
    ../../modules/nixos/features/hardware/bluetooth.nix
    ../../modules/nixos/features/services/ssh.nix
    ../../modules/nixos/features/virtualization/docker.nix
    ../../modules/nixos/features/networking

    # Users on this machine
    ../../users/hollywood
  ];

  # ==========================================================================
  # Host Identity
  # ==========================================================================

  networking.hostName = vars.hostname;

  # ==========================================================================
  # Boot Configuration
  # ==========================================================================

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ==========================================================================
  # Home Manager
  # ==========================================================================

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs vars; };
  };

  # ==========================================================================
  # Packages
  # ==========================================================================

  environment.systemPackages = with pkgs; [
    # Core utilities
    git
    wget
    curl
    tree
    ripgrep
    fd
    file
    unzip

    # Development
    gcc
    gnumake

    # Networking
    tailscale
  ];

  # ==========================================================================
  # System State Version
  # ==========================================================================

  system.stateVersion = vars.stateVersion;
}
