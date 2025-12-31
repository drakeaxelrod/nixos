# Boot configuration - bootloader selection, kernel, firmware
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.core.boot;
in
{
  imports = [
    ./systemd.nix
    ./limine.nix
    ./grub.nix
  ];

  options.modules.core.boot = {
    # ==========================================================================
    # Bootloader Selection
    # ==========================================================================

    loader = lib.mkOption {
      type = lib.types.enum [ "systemd" "limine" "grub" ];
      default = "systemd";
      description = ''
        Which bootloader to use:
        - systemd: Simple, clean, UEFI-only (default)
        - limine:  Modern, stylish, great for specialisations
        - grub:    Classic, feature-rich, BIOS+UEFI support
      '';
    };

    # ==========================================================================
    # Common Options
    # ==========================================================================

    kernelPackage = lib.mkOption {
      type = lib.types.str;
      default = "linuxPackages_6_12";
      description = "Kernel package to use (e.g., linuxPackages_6_12, linuxPackages_latest)";
    };

    maxGenerations = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = "Number of boot generations to show in menu";
    };

    timeout = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = "Boot menu timeout in seconds";
    };

    efiMountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/boot/efi";
      description = "EFI system partition mount point";
    };
  };

  config = {
    # ==========================================================================
    # Common Boot Configuration
    # ==========================================================================

    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = cfg.efiMountPoint;

    # ==========================================================================
    # Kernel Configuration
    # ==========================================================================

    boot.kernelPackages = pkgs.${cfg.kernelPackage};

    # Base kernel parameters (IOMMU always enabled for VFIO capability)
    boot.kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
    ];

    # Blacklist nouveau (always, regardless of VFIO mode)
    boot.blacklistedKernelModules = [ "nouveau" ];

    # Firmware
    hardware.enableRedistributableFirmware = true;
  };
}
