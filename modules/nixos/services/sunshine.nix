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

    # Upstream's sunshine module still sets the obsolete avahi.publish.*
    # options (via mkDefault), which triggers deprecation warnings. Null them
    # out and set the equivalent new-style settings so Moonlight discovery
    # keeps working. Remove once nixpkgs' sunshine module is updated.
    services.avahi = {
      publish.enable = null;
      publish.userServices = null;
      settings.publish = {
        disable-publishing = false;
        disable-user-service-publishing = false;
        publish-addresses = true;
      };
    };
  };
}
