# Base networking configuration
{ config, lib, pkgs, ... }:

{
  config = {
    # Disable DHCP globally - let NetworkManager handle it
    networking.useDHCP = false;

    # NetworkManager for easy network management
    networking.networkmanager = {
      enable = true;
      # Don't manage virtual interfaces
      unmanaged = [ "virbr0" "docker0" ];
    };

    # Disable slow NetworkManager wait service
    systemd.services.NetworkManager-wait-online.enable = false;

    # Disable scripted networking - NetworkManager handles everything
    systemd.services.network-setup.enable = false;
  };
}
