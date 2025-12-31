# Looking Glass - low-latency VM display
#
# Usage:
#   modules.vfio.lookingGlass = {
#     enable = true;
#     users = [ "draxel" ];  # Users who can use Looking Glass
#   };
#
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.vfio;
  lgCfg = cfg.lookingGlass;
  firstUser = if lgCfg.users != [] then lib.head lgCfg.users else "root";
in
{
  options.modules.vfio.lookingGlass = {
    enable = lib.mkEnableOption "Looking Glass for low-latency VM display";

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = [ "draxel" ];
      description = "Users who can access Looking Glass";
    };

    shmSize = lib.mkOption {
      type = lib.types.int;
      default = 128;
      description = "KVMFR shared memory size in MB (128 for 4K, 64 for 1440p)";
    };
  };

  config = lib.mkIf (cfg.enable && lgCfg.enable && lgCfg.users != []) {
    # KVMFR kernel module
    boot.extraModulePackages = with config.boot.kernelPackages; [ kvmfr ];
    boot.kernelModules = [ "kvmfr" ];

    boot.extraModprobeConfig = ''
      options kvmfr static_size_mb=${toString lgCfg.shmSize}
    '';

    # Shared memory - owned by first user, group access for others
    systemd.tmpfiles.rules = [
      "f /dev/shm/looking-glass 0660 ${firstUser} libvirtd -"
    ];

    # udev rules - group-based access
    services.udev.extraRules = ''
      SUBSYSTEM=="kvmfr", GROUP="libvirtd", MODE="0660"
    '';

    # Add all users to libvirtd group for access
    users.groups.libvirtd.members = lgCfg.users;

    environment.systemPackages = [ pkgs.looking-glass-client ];
  };
}
