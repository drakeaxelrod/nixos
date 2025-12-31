# Docker container runtime
{ config, pkgs, lib, ... }:

{
  virtualisation.docker = {
    enable = true;
    storageDriver = lib.mkDefault "btrfs";  # Override if not using btrfs
  };
}
