# Looking Glass - low-latency VM display
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.vfio;
  userCfg = config.modules.users;
in
{
  options.modules.vfio.lookingGlass = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Looking Glass for low-latency VM display";
    };

    shmSize = lib.mkOption {
      type = lib.types.int;
      default = 128;
      description = "KVMFR shared memory size in MB (128 for 4K, 64 for 1440p)";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.lookingGlass.enable) {
    # KVMFR kernel module
    boot.extraModulePackages = with config.boot.kernelPackages; [ kvmfr ];
    boot.kernelModules = [ "kvmfr" ];

    # Configure KVMFR shared memory size
    boot.extraModprobeConfig = ''
      options kvmfr static_size_mb=${toString cfg.lookingGlass.shmSize}
    '';

    # Shared memory device
    systemd.tmpfiles.rules = [
      "f /dev/shm/looking-glass 0660 ${userCfg.primaryUser} libvirtd -"
    ];

    # udev rules for KVMFR device
    services.udev.extraRules = ''
      SUBSYSTEM=="kvmfr", OWNER="${userCfg.primaryUser}", GROUP="libvirtd", MODE="0660"
    '';

    # Looking Glass client
    environment.systemPackages = [ pkgs.looking-glass-client ];
  };
}
