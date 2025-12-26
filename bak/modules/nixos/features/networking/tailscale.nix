# Tailscale VPN
{ config, pkgs, lib, ... }:

{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    openFirewall = true;
  };
}
