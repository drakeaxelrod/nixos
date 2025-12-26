# Common system packages
{ config, lib, pkgs, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      # System utilities
      vim
      git
      htop
      btop
      wget
      curl
      tree
      ripgrep
      fd

      # Hardware info
      pciutils
      usbutils
      lm_sensors
      nvtopPackages.full
      mesa-demos
      vulkan-tools

      # Networking
      bridge-utils

      # Development
      gcc
      gnumake
    ];
  };
}
