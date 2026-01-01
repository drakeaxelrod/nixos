# Tailscale VPN
{ config, lib, pkgs, ... }:

{
  options.modules.networking.tailscale = {
    enable = lib.mkEnableOption "Tailscale VPN";

    exitNode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Allow this machine to be an exit node";
    };

    subnetRouter = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Allow this machine to be a subnet router";
    };
  };

  config = lib.mkIf config.modules.networking.tailscale.enable {
    services.tailscale = {
      enable = true;
      useRoutingFeatures =
        if config.modules.networking.tailscale.exitNode && config.modules.networking.tailscale.subnetRouter then "both"
        else if config.modules.networking.tailscale.exitNode then "client"
        else if config.modules.networking.tailscale.subnetRouter then "server"
        else "none";
    };

    environment.systemPackages = with pkgs; [
      tailscale
      trayscale # GUI
      ktailctl # GUI
      # tail-tray # Tray icon
    ];
  };
}
