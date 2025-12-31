# GNOME Desktop Environment
{ config, lib, pkgs, ... }:

{
  options.modules.desktop.gnome = {
    enable = lib.mkEnableOption "GNOME desktop environment";

    excludePackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        gnome-tour
        gnome-music
        epiphany
        geary
      ];
      description = "GNOME packages to exclude";
    };
  };

  config = lib.mkIf config.modules.desktop.gnome.enable {
    services.xserver.enable = true;
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    # Remove bloat
    environment.gnome.excludePackages = config.modules.desktop.gnome.excludePackages;

    # GNOME extensions
    environment.systemPackages = with pkgs; [
      gnome-extension-manager
      gnomeExtensions.appindicator
      gnomeExtensions.dash-to-dock
    ];
  };
}
