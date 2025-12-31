# Bridge network for VMs
#
# This module creates a network bridge for VMs to share the host's network.
# VMs on a bridge get IPs from your router (same subnet as host).
#
# IMPORTANT: Most users don't need this!
#
# Networking options (easiest to hardest):
# 1. NAT (default) - Works out of the box, VMs can access internet
#    No configuration needed, libvirt provides virbr0 automatically
#
# 2. Macvtap - Direct NIC attachment, no bridge needed, no rebuild for interface changes
#    Set network.type = "macvtap" and network.interface in your VM config
#
# 3. NetworkManager bridge - Create bridge at runtime, no rebuild needed
#    nmcli con add type bridge con-name br0 ifname br0
#    nmcli con add type ethernet con-name br0-port ifname enp6s0 master br0
#
# 4. NixOS bridge (this module) - Declarative but requires rebuild if interface changes
#
# Usage:
#   modules.networking.bridge = {
#     enable = true;
#     interface = "enp6s0";  # Your physical interface (find with: ip link)
#   };
#
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.networking.bridge;
in
{
  options.modules.networking.bridge = {
    enable = lib.mkEnableOption "declarative network bridge for VMs";

    name = lib.mkOption {
      type = lib.types.str;
      default = "br0";
      description = "Bridge interface name";
    };

    interface = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "enp6s0";
      description = ''
        Physical interface to bridge. Required when enable = true.
        Find yours with: ip link | grep -E '^[0-9]+:' | grep -v 'lo\|vir\|docker'
      '';
    };

    useDHCP = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use DHCP on the bridge interface";
    };

    staticIP = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "192.168.1.100/24";
      description = "Static IP with CIDR notation (when useDHCP = false)";
    };

    gateway = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "192.168.1.1";
      description = "Default gateway (when useDHCP = false)";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.interface != "";
        message = ''
          modules.networking.bridge.interface must be set.
          Find your interface with: ip link | grep -E '^[0-9]+:' | grep -v 'lo\|vir\|docker'

          Alternative: Use macvtap networking in your VM config which doesn't require
          a bridge and doesn't need rebuilds when interface names change:

            virtualisation.vms.myvm.network = {
              type = "macvtap";
              interface = "enp6s0";
            };
        '';
      }
    ];

    # Create the bridge
    networking.bridges.${cfg.name} = {
      interfaces = [ cfg.interface ];
    };

    # Configure IP on bridge (physical interface gets none)
    networking.interfaces = {
      ${cfg.name} = if cfg.useDHCP then {
        useDHCP = true;
      } else {
        ipv4.addresses = lib.optional (cfg.staticIP != null) {
          address = lib.head (lib.splitString "/" cfg.staticIP);
          prefixLength = lib.toInt (lib.last (lib.splitString "/" cfg.staticIP));
        };
      };
      ${cfg.interface}.useDHCP = false;
    };

    # Set default gateway for static IP
    networking.defaultGateway = lib.mkIf (!cfg.useDHCP && cfg.gateway != null) cfg.gateway;

    # Trust the bridge interface in firewall
    networking.firewall.trustedInterfaces = [ cfg.name ];
  };
}
