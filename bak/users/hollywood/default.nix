# System-level user configuration for hollywood
# Developer account

{ config, pkgs, lib, vars, ... }:

{
  # ==========================================================================
  # User Account
  # ==========================================================================

  users.users.hollywood = {
    isNormalUser = true;
    description = "Hollywood";
    initialPassword = "changeme";
    extraGroups = [
      "wheel"      # sudo access
      "networkmanager"
      "docker"
      "video"
      "audio"
    ];
    shell = pkgs.zsh;
  };

  # ==========================================================================
  # Home-Manager Configuration
  # ==========================================================================

  home-manager.users.hollywood = import ./home;
}
