# Bridge network for VMs
{ config, lib, pkgs, ... }:

{
  options.modules.networking.bridge = {
    enable = lib.mkEnableOption "VM bridge network";

    name = lib.mkOption {
      type = lib.types.str;
      default = "br0";
      description = "Bridge interface name";
    };

    interface = lib.mkOption {
      type = lib.types.str;
      default = "eth0";
      description = ''
        Physical interface to bridge.
        Update after install with: ip link
        Common: enp6s0 (PCIe ethernet), wlp5s0 (WiFi)
      '';
    };
  };

  config = lib.mkIf config.modules.networking.bridge.enable (let
    cfg = config.modules.networking.bridge;
  in {
    networking.bridges.${cfg.name} = {
      interfaces = [ cfg.interface ];
    };

    networking.interfaces = {
      ${cfg.name}.useDHCP = true;
      ${cfg.interface}.useDHCP = false;
    };
  });
}
