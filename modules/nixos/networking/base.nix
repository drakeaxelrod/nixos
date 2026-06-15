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

    # systemd-resolved provides split DNS. Without it, Tailscale runs in
    # "direct" mode and overwrites /etc/resolv.conf with ONLY its MagicDNS
    # resolver (100.100.100.100) — so any tailscaled flap (e.g. during a
    # nixos-rebuild switch) kills DNS for everything, including the binary
    # caches, and breaks builds mid-download. With resolved, tailnet names
    # (*.ts.net) go to MagicDNS while everything else uses the normal
    # NetworkManager/upstream resolver.
    services.resolved.enable = true;

    # Disable slow NetworkManager wait service
    systemd.services.NetworkManager-wait-online.enable = false;

    # Disable scripted networking - NetworkManager handles everything
    systemd.services.network-setup.enable = false;
  };
}
