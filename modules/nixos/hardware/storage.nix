# Storage configuration - Btrfs maintenance
{ config, lib, pkgs, ... }:

{
  options.modules.hardware.storage = {
    btrfsScrub = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable monthly Btrfs scrub";
    };

    scrubInterval = lib.mkOption {
      type = lib.types.str;
      default = "monthly";
      description = "Btrfs scrub interval";
    };
  };

  config = lib.mkIf config.modules.hardware.storage.btrfsScrub {
    services.btrfs.autoScrub = {
      enable = true;
      interval = config.modules.hardware.storage.scrubInterval;
      fileSystems = [ "/" ];
    };
  };
}
