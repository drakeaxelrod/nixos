# SDDM Display Manager
# System-level configuration for Simple Desktop Display Manager
# Can be used with Plasma or independently
{ config, lib, pkgs, ... }:

{
  options.modules.desktop.sddm = {
    enable = lib.mkEnableOption "SDDM display manager";

    wayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Wayland session support";
    };

    theme = lib.mkOption {
      type = lib.types.str;
      default = "breeze";
      description = "SDDM theme to use";
    };
  };

  config = lib.mkIf config.modules.desktop.sddm.enable {
    # X11 may be required for SDDM itself
    services.xserver.enable = true;

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = config.modules.desktop.sddm.wayland;
      theme = config.modules.desktop.sddm.theme;
    };

    # Enable XWayland if using Wayland
    programs.xwayland.enable = lib.mkIf config.modules.desktop.sddm.wayland true;
  };
}
