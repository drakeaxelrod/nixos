# VFIO GPU Passthrough - Automatic Boot Configuration
#
# This module automatically handles all required boot parameters for VFIO.
# Users don't need to manually configure IOMMU, kernel modules, or blacklisting.
# Everything is automatically overridden with appropriate priorities.
#
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.vfio;
in
{
  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Base VFIO configuration (always when enabled)
    {
      # =========================================================================
      # Boot Parameters - Automatically Override
      # =========================================================================
      # VFIO requires IOMMU to be enabled. We automatically ensure this is set,
      # overriding any defaults from the boot module.

      boot.kernelParams = lib.mkAfter [
        "amd_iommu=on"  # Enable AMD IOMMU (required for VFIO)
        "iommu=pt"      # Use passthrough mode for best performance
      ];

      # Load VFIO kernel modules
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
      # =========================================================================
      # Primary Mode Boot Configuration
      # =========================================================================
      # In primary mode, we isolate the GPU for VM use only.
      # Host uses integrated graphics (AMD iGPU).

      # Load VFIO modules early in initrd to claim GPU before nvidia
      boot.initrd.kernelModules = [ "vfio_pci" "vfio" "vfio_iommu_type1" ];

      # Bind GPU to vfio-pci at boot (automatically appended)
      boot.kernelParams = lib.mkAfter (lib.optionals (cfg.gpuPciIds != []) [
        "vfio-pci.ids=${lib.concatStringsSep "," cfg.gpuPciIds}"
      ]);

      # Blacklist ALL nvidia modules (merged with boot module's nouveau blacklist)
      boot.blacklistedKernelModules = lib.mkAfter [
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
