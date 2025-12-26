# Base networking configuration
{ config, lib, pkgs, ... }:

{
  config = {
    networking.networkmanager.enable = true;
  };
}
