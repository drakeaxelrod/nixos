# draxel - Self-contained user module
#
# Combines NixOS user configuration with Home Manager.
# Import this module in mkHost to add the user to a host.
#
{ config, lib, pkgs, ... }:

{
  # NixOS user configuration
  users.users.draxel = {
    isNormalUser = true;
    description = "draxel";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "changeme";
  };

  # Home Manager configuration
  home-manager.users.draxel = import ./home;
}
