# Docker container runtime
{ config, lib, pkgs, ... }:

{
  options.modules.virtualization.docker = {
    enable = lib.mkEnableOption "Docker container runtime";

    storageDriver = lib.mkOption {
      type = lib.types.str;
      default = "btrfs";
      description = "Docker storage driver (btrfs, overlay2)";
    };
  };

  config = lib.mkIf config.modules.virtualization.docker.enable {
    virtualisation.docker = {
      enable = true;
      storageDriver = config.modules.virtualization.docker.storageDriver;
    };
  };
}
