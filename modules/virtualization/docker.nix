# Docker container runtime
#
# Usage:
#   modules.virtualization.docker = {
#     enable = true;
#     users = [ "draxel" ];  # Users who can use docker
#   };
#
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.virtualization.docker;
in
{
  options.modules.virtualization.docker = {
    enable = lib.mkEnableOption "Docker container runtime";

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = [ "draxel" ];
      description = "Users who can use docker (added to docker group)";
    };

    storageDriver = lib.mkOption {
      type = lib.types.str;
      default = "btrfs";
      description = "Docker storage driver (btrfs, overlay2)";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      storageDriver = cfg.storageDriver;
    };

    # Add users to docker group
    users.groups.docker.members = cfg.users;
  };
}
