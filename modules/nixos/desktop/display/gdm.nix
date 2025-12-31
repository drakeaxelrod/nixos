# GDM Display Manager
# System-level configuration for GNOME Display Manager
# Can be used with GNOME or independently
{ config, lib, pkgs, ... }:

{
  options.modules.desktop.gdm = {
    enable = lib.mkEnableOption "GDM display manager";

    wayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Wayland session support";
    };
  };

  config = lib.mkIf config.modules.desktop.gdm.enable {
    # X11 is still required for GDM, even on Wayland
    services.xserver = {
      enable = true;
      excludePackages = [ pkgs.xterm ];
    };

    services.displayManager.gdm = {
      enable = true;
      wayland = config.modules.desktop.gdm.wayland;
    };

    # Enable XWayland if using Wayland
    programs.xwayland.enable = lib.mkIf config.modules.desktop.gdm.wayland true;
  };
}
