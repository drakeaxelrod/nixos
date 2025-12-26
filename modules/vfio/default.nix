# VFIO GPU Passthrough module
{ config, lib, pkgs, ... }:

{
  imports = [
    ./core.nix
    ./looking-glass.nix
    ./scream.nix
  ];

  options.modules.vfio = {
    enable = lib.mkEnableOption "VFIO GPU passthrough";

    primaryMode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        When true, GPU is ALWAYS isolated for VM passthrough (VFIO primary mode).
        NVIDIA driver never loads, host uses AMD iGPU exclusively.
        When false, GPU is available on host (for CUDA, gaming, etc.).
      '';
    };

    gpuPciIds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = [ "10de:2782" "10de:22bc" ];
      description = ''
        PCI vendor:device IDs for GPU passthrough.
        Find with: lspci -nn | grep -i nvidia
        Format: "vendor:device" (e.g., "10de:2782" for RTX 5070 Ti)
      '';
    };

    gpuPciAddresses = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = [ "0000:01:00.0" "0000:01:00.1" ];
      description = ''
        Full PCI addresses for GPU (used in libvirt XML).
        Find with: lspci -D | grep -i nvidia
        Format: "0000:XX:XX.X"
      '';
    };

    usbPassthroughVendors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "045e"  # Microsoft (Xbox controllers)
        "054c"  # Sony (PlayStation controllers)
        "057e"  # Nintendo (Switch controllers)
        "1050"  # Yubico (YubiKey)
      ];
      description = "USB vendor IDs for device passthrough";
    };
  };
}
