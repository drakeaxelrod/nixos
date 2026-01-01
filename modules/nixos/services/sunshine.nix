# Sunshine - Self-hosted game streaming server
# Works with Moonlight client for low-latency game streaming
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.services.sunshine;
in
{
  options.modules.services.sunshine = {
    enable = lib.mkEnableOption "Sunshine game streaming server";

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Start Sunshine automatically on boot";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open firewall ports for Sunshine (TCP: 47984-47990, UDP: 47998-48010)";
    };
  };

  config = lib.mkIf cfg.enable {
    services.sunshine = {
      enable = true;
      autoStart = cfg.autoStart;
      capSysAdmin = true;  # Required for KMS capture
      openFirewall = cfg.openFirewall;
    };
  };
}
