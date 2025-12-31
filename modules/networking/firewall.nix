# Firewall configuration
{ config, lib, pkgs, ... }:

{
  options.modules.networking.firewall = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable firewall";
    };

    trustedInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "tailscale0" "virbr0" ];
      description = "Interfaces excluded from firewall rules";
    };
  };

  config = {
    networking.firewall = {
      enable = config.modules.networking.firewall.enable;
      trustedInterfaces = config.modules.networking.firewall.trustedInterfaces
        ++ lib.optional config.modules.networking.bridge.enable config.modules.networking.bridge.name;
    };
  };
}
