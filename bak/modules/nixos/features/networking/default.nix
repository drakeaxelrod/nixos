# Core networking with NetworkManager
{ config, pkgs, lib, ... }:

{
  networking.useDHCP = false;

  # Disable scripted networking - NetworkManager handles everything
  systemd.services.network-setup.enable = false;

  # NetworkManager for easy network management
  networking.networkmanager = {
    enable = true;
    unmanaged = [ "virbr0" "docker0" ];
  };

  # Basic firewall
  networking.firewall = {
    enable = true;
  };

  # Disable slow NetworkManager wait service
  systemd.services.NetworkManager-wait-online.enable = false;
}
