# Limine - Modern, stylish bootloader with great specialisation support
#
# Boot menu format:
#   NixOS 25.05.20250115.abc1234 (Generation 42)
#   NixOS 25.05.20250115.abc1234 (Generation 42, vfio)
#
# Each entry shows: NixOS version, date, git rev, generation number,
# and specialisation tag if applicable.
#
# https://wiki.nixos.org/wiki/Limine
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.system.boot;
in
{
  config = lib.mkIf (cfg.loader == "limine") {
    # Boot timeout (shared across all bootloaders)
    boot.loader.timeout = cfg.timeout;

    boot.loader.limine = {
      enable = true;
      efiSupport = true;
      maxGenerations = cfg.maxGenerations;

      # Security: disable kernel param editing at boot
      enableEditor = false;

      # Validate boot files for integrity
      validateChecksums = true;

      # Optional styling:
      # style = {
      #   wallpapers = [ ./boot-wallpaper.png ];
      #   wallpaperStyle = "stretched";
      #   backdrop = "1a1b26";  # Tokyo Night background
      # };
    };
  };
}
