# WireGuard VPN client support
#
# Enables WireGuard tools and kernel module.
# Add connections via Plasma GUI or: nmcli connection import type wireguard file wg0.conf
#
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.networking.wireguard;
in
{
  options.modules.networking.wireguard = {
    enable = lib.mkEnableOption "WireGuard VPN client support";
  };

  config = lib.mkIf cfg.enable {
    # WireGuard CLI tools (wg, wg-quick)
    environment.systemPackages = with pkgs; [
      wireguard-tools
    ];
  };
}
