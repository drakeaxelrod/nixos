# Systemd-boot - Simple, clean, UEFI-only bootloader
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.system.boot;
in
{
  config = lib.mkIf (cfg.loader == "systemd") {
    boot.loader.systemd-boot = {
      enable = true;
      configurationLimit = cfg.maxGenerations;

      # Clean console output
      consoleMode = "auto";

      # Editor disabled for security
      editor = false;
    };

    boot.loader.timeout = cfg.timeout;
  };
}
