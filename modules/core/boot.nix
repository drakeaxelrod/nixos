# Boot configuration - bootloader, kernel, firmware
{ config, lib, pkgs, ... }:

{
  options.modules.core.boot = {
    kernelPackage = lib.mkOption {
      type = lib.types.str;
      default = "linuxPackages_6_12";
      description = "Kernel package to use (e.g., linuxPackages_6_12, linuxPackages_latest)";
    };

    configurationLimit = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Number of boot configurations to keep";
    };
  };

  config = {
    # Systemd-boot
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot/efi";
    boot.loader.systemd-boot.configurationLimit = config.modules.core.boot.configurationLimit;

    # Kernel - use 6.12 LTS for NVIDIA compatibility
    boot.kernelPackages = pkgs.${config.modules.core.boot.kernelPackage};

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
