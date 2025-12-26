# User configuration for draxel
# This defines both the NixOS user and home-manager config
{ config, pkgs, lib, vars, ... }:

{
  # ==========================================================================
  # NixOS User Account
  # ==========================================================================

  users.users.draxel = {
    isNormalUser = true;
    description = "draxel";
    shell = pkgs.zsh;
    initialPassword = "changeme";  # Change on first login!
    extraGroups = [
      "wheel"
      "networkmanager"
      "libvirtd"
      "docker"
      "input"
      "kvm"
      "plugdev"
    ];
  };

  # ==========================================================================
  # Home-Manager Configuration
  # ==========================================================================

  home-manager.users.draxel = import ./home;
}
