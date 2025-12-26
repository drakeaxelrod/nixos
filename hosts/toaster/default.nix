# Toaster - Gaming + Pentesting Workstation
#
# Hardware: AMD Ryzen 7 7800X3D, NVIDIA RTX 5070 Ti, 64GB DDR5, 2x 2TB NVMe
# Features: VFIO GPU passthrough (primary), Looking Glass, Impermanence
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ./disko.nix

    # Feature modules
    ../../modules/desktop
    ../../modules/vfio
    ../../modules/virtualization
    ../../modules/impermanence

    # Declarative VMs
    ../../vms/windows11.nix
  ];

  # ==========================================================================
  # System Identity
  # ==========================================================================

  networking.hostName = "toaster";
  system.stateVersion = "25.11";

  # ==========================================================================
  # Hardware Features
  # ==========================================================================

  modules.hardware.amd-cpu.enable = true;
  modules.hardware.amd-gpu.enable = true;

  # ==========================================================================
  # VFIO Configuration (GPU Passthrough)
  # ==========================================================================

  modules.vfio = {
    enable = true;
    primaryMode = true;  # GPU always isolated for VM passthrough

    # PLACEHOLDER - Update after first boot!
    # Run: lspci -nn | grep -i nvidia
    gpuPciIds = [
      "10de:XXXX"  # RTX 5070 Ti GPU
      "10de:XXXX"  # RTX 5070 Ti Audio
    ];

    # PLACEHOLDER - Update after first boot!
    # Run: lspci -D | grep -i nvidia
    gpuPciAddresses = [
      "0000:01:00.0"  # GPU
      "0000:01:00.1"  # Audio
    ];

    lookingGlass = {
      enable = true;
      shmSize = 128;  # 128MB for 4K
    };

    scream.enable = true;
  };

  # ==========================================================================
  # Virtualization
  # ==========================================================================

  modules.virtualization.libvirt.enable = true;
  modules.virtualization.docker.enable = true;

  # ==========================================================================
  # Desktop Environment
  # ==========================================================================

  modules.desktop.gnome.enable = true;
  modules.desktop.wayland.enable = true;

  # ==========================================================================
  # Networking
  # ==========================================================================

  modules.networking.bridge = {
    enable = true;
    name = "br0";
    interface = "eth0";  # PLACEHOLDER - Update with: ip link
  };

  modules.networking.tailscale.enable = true;

  # ==========================================================================
  # Services
  # ==========================================================================

  modules.services.openssh.enable = true;
  modules.services.btrbk.enable = true;

  # ==========================================================================
  # Impermanence (Ephemeral Root)
  # ==========================================================================

  # Disabled by default - enable after creating @rootfs-blank snapshot
  # modules.impermanence.enable = true;

  # ==========================================================================
  # SOPS Secrets
  # ==========================================================================

  # Disabled by default - enable after setting up age keys
  # modules.security.sops.enable = true;

  # ==========================================================================
  # Windows 11 VM
  # ==========================================================================

  modules.vms.windows11 = {
    enable = true;
    name = "win11";
    memory = 32768;      # 32GB
    vcpus = 12;          # 12 threads
    cores = 6;           # 6 physical cores
    hugepages = true;
    hugepagesCount = 32; # 32GB hugepages
  };

  # ==========================================================================
  # User Configuration
  # ==========================================================================

  modules.users = {
    primaryUser = "draxel";
    users.draxel = {
      description = "draxel";
      shell = pkgs.zsh;
      extraGroups = [ "wheel" "networkmanager" "libvirtd" "docker" "input" "kvm" ];
      initialPassword = "changeme";
    };
  };
}
