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

    # Import-based pattern: explicitly import only needed modules

    # Desktop environment
    modules.nixos.desktop.display.gdm
    modules.nixos.desktop.managers.gnome

    # Hardware
    modules.nixos.hardware.audio

    # Services
    modules.nixos.services.openssh

    # Security
    modules.nixos.security.base
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

  modules.system.boot = {
    loader = "systemd";
    maxGenerations = 10;
    timeout = 3;
  };

  # ==========================================================================
  # Hardware
  # ==========================================================================

  # Hardware modules imported above - configure here
  # Import additional hardware modules as needed:
  # modules.nixos.hardware.amd
  # modules.nixos.hardware.nvidia
  # modules.nixos.hardware.bluetooth
  modules.hardware.audio.enable = true;

  # ==========================================================================
  # Desktop Environment
  # ==========================================================================

  # Desktop modules imported above - configure here
  modules.desktop.gnome.enable = true;
  modules.desktop.gdm.enable = true;

  # ==========================================================================
  # Networking
  # ==========================================================================

  # Import additional networking modules as needed:
  # modules.nixos.networking.tailscale

  # ==========================================================================
  # Services
  # ==========================================================================

  # Service modules imported above - configure here
  # Import additional services as needed:
  # modules.nixos.services.printing
  modules.services.openssh.enable = true;

  # ==========================================================================
  # Security
  # ==========================================================================

  # Security modules imported above - configure here
  modules.security.base.enable = true;

  # ==========================================================================
  # Virtualization (optional)
  # ==========================================================================

  # Import virtualization modules as needed:
  # modules.nixos.virtualization.docker
  # modules.nixos.virtualization.libvirt

  # Then configure:
  # modules.virtualization.docker = {
  #   enable = true;
  #   users = [ users.draxel ];
  # };

  # modules.virtualization.libvirt = {
  #   enable = true;
  #   users = [ users.draxel ];
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
