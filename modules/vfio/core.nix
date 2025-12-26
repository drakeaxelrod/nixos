# VFIO Core - kernel modules and GPU isolation
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.vfio;
in
{
  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Base VFIO configuration (always when enabled)
    {
      boot.kernelModules = [ "vfio_pci" "vfio" "vfio_iommu_type1" ];

      # USB passthrough permissions
      services.udev.extraRules = ''
        # USB device passthrough permissions
        ${lib.concatMapStringsSep "\n" (vendor:
          ''SUBSYSTEM=="usb", ATTR{idVendor}=="${vendor}", MODE="0666"''
        ) cfg.usbPassthroughVendors}
      '';
    }

    # VFIO Primary Mode - GPU always isolated
    (lib.mkIf cfg.primaryMode {
      # Load VFIO modules early in initrd to claim GPU before nvidia
      boot.initrd.kernelModules = [ "vfio_pci" "vfio" "vfio_iommu_type1" ];

      # Bind GPU to vfio-pci at boot
      boot.kernelParams = lib.optionals (cfg.gpuPciIds != []) [
        "vfio-pci.ids=${lib.concatStringsSep "," cfg.gpuPciIds}"
      ];

      # Blacklist ALL nvidia modules
      boot.blacklistedKernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];

      # Use modesetting driver (AMD iGPU only)
      services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];

      # Disable nvidia-container-toolkit
      hardware.nvidia-container-toolkit.enable = lib.mkForce false;
    })

    # Host GPU Mode - NVIDIA on host (for CUDA, gaming)
    (lib.mkIf (!cfg.primaryMode) {
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        modesetting.enable = true;
        open = true;  # RTX 50 series uses open kernel modules
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.latest;
      };

      # Docker GPU access
      hardware.nvidia-container-toolkit.enable = true;
    })
  ]);
}
