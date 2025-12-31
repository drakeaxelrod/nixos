# NixOS - Simple Default Configuration
#
# A minimal, clean NixOS configuration for general use.
# Perfect for testing, development, or as a base to customize.

{ config, pkgs, lib, inputs, meta, ... }:

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
  ];

  # ==========================================================================
  # System Identity
  # ==========================================================================
  # Derived from mkHost - no need to set here
  # networking.hostName = meta.hostname;      # "nixos"
  # system.stateVersion = meta.stateVersion;  # "25.11"

  # ==========================================================================
  # Bootloader
  # ==========================================================================

  modules.core.boot = {
    loader = "systemd";
    maxGenerations = 10;
    timeout = 3;
  };

  # ==========================================================================
  # Hardware
  # ==========================================================================

  # Enable based on your hardware
  # modules.hardware.amd.enable = true;      # AMD CPU + GPU
  # modules.hardware.nvidia.enable = true;   # NVIDIA GPU
  modules.hardware.audio.enable = true;
  # modules.hardware.bluetooth.enable = true;

  # ==========================================================================
  # Desktop Environment
  # ==========================================================================

  modules.desktop.gnome.enable = true;
  modules.desktop.wayland.enable = true;

  # ==========================================================================
  # Networking
  # ==========================================================================

  # modules.networking.tailscale.enable = true;

  # ==========================================================================
  # Services
  # ==========================================================================

  modules.services.openssh.enable = true;
  # modules.services.printing.enable = true;

  # ==========================================================================
  # Security
  # ==========================================================================

  modules.security.base.enable = true;

  # ==========================================================================
  # Virtualization (optional)
  # ==========================================================================

  # modules.virtualization.docker = {
  #   enable = true;
  #   users = [ users.draxel ];  # Derived from meta.users
  # };

  # modules.virtualization.libvirt = {
  #   enable = true;
  #   users = [ users.draxel ];  # Derived from meta.users
  # };

  # ==========================================================================
  # System Packages
  # ==========================================================================

  environment.systemPackages = with pkgs; [
    # Core utilities
    git
    wget
    curl
    tree
    htop
    btop

    # File tools
    ripgrep
    fd
    file
    unzip
    zip

    # Development basics
    gcc
    gnumake
  ];

  # ==========================================================================
  # Users
  # ==========================================================================
  # Users are defined as self-contained modules in users/ directory
  # and composed in flake.nix via: users = with self.users; [ draxel ];
}
