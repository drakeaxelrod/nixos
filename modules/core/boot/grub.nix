# GRUB - Classic, feature-rich bootloader with BIOS+UEFI support
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.core.boot;
in
{
  config = lib.mkIf (cfg.loader == "grub") {
    boot.loader.grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";  # EFI install, no MBR

      configurationLimit = cfg.maxGenerations;

      # Use graphical mode
      gfxmodeEfi = "auto";

      # Optional: theme
      # theme = pkgs.nixos-grub2-theme;
    };

    boot.loader.timeout = cfg.timeout;
  };
}
