# AMD CPU optimizations
{ config, lib, pkgs, ... }:

{
  options.modules.hardware.amd-cpu = {
    enable = lib.mkEnableOption "AMD CPU optimizations";

    enableSME = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable AMD Secure Memory Encryption";
    };

    enablePstate = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable AMD P-State driver for better power management";
    };
  };

  config = lib.mkIf config.modules.hardware.amd-cpu.enable {
    boot.kernelModules = [ "kvm-amd" ];

    boot.kernelParams = lib.mkMerge [
      (lib.mkIf config.modules.hardware.amd-cpu.enableSME [ "mem_encrypt=on" ])
      (lib.mkIf config.modules.hardware.amd-cpu.enablePstate [ "amd_pstate=active" ])
    ];

    # AMD microcode updates
    hardware.cpu.amd.updateMicrocode = true;
  };
}
