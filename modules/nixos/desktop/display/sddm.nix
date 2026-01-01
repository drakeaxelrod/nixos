# SDDM Display Manager
# System-level configuration for Simple Desktop Display Manager
# Can be used with Plasma or independently
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.desktop.sddm;
in
{
  options.modules.desktop.sddm = {
    enable = lib.mkEnableOption "SDDM display manager";

    wayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Wayland session support";
    };

    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to wallpaper image for SDDM login screen";
    };
  };

  config = lib.mkIf cfg.enable {
    # X11 may be required for SDDM itself
    services.xserver.enable = true;

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = cfg.wayland;
      theme = "breeze";
    };

    # Configure breeze theme wallpaper
    environment.etc."sddm/themes/breeze/theme.conf.user".text = lib.mkIf (cfg.wallpaper != null) ''
      [General]
      background=${cfg.wallpaper}
    '';

    # Enable XWayland if using Wayland
    programs.xwayland.enable = lib.mkIf cfg.wayland true;
  };
}
