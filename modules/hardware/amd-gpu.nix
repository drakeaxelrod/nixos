# AMD iGPU configuration (Radeon 780M / RDNA 3)
{ config, lib, pkgs, ... }:

{
  options.modules.hardware.amd-gpu = {
    enable = lib.mkEnableOption "AMD iGPU support";

    earlyModesetting = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Load amdgpu in initrd for early KMS";
    };
  };

  config = lib.mkIf config.modules.hardware.amd-gpu.enable {
    # Early KMS for smooth boot
    boot.initrd.kernelModules = lib.mkIf config.modules.hardware.amd-gpu.earlyModesetting [ "amdgpu" ];

    # AMDGPU kernel parameters
    boot.kernelParams = [
      "amdgpu.dc=1"              # Display Core (required for modern displays)
      "amdgpu.dcdebugmask=0x10"  # EDID workarounds
    ];

    # Hardware acceleration
    hardware.graphics = {
      enable = true;
      enable32Bit = true;  # For 32-bit games/apps
    };

    # AMDGPU initrd support
    hardware.amdgpu.initrd.enable = config.modules.hardware.amd-gpu.earlyModesetting;
  };
}
