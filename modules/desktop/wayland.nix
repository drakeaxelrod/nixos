# Wayland configuration
{ config, lib, pkgs, ... }:

{
  options.modules.desktop.wayland = {
    enable = lib.mkEnableOption "Wayland session configuration";
  };

  config = lib.mkIf config.modules.desktop.wayland.enable {
    # Environment variables for Wayland
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";           # Electron apps use Wayland
      MOZ_ENABLE_WAYLAND = "1";       # Firefox Wayland
      QT_QPA_PLATFORM = "wayland";    # Qt apps use Wayland
      SDL_VIDEODRIVER = "wayland";    # SDL games use Wayland
      XDG_SESSION_TYPE = "wayland";
    };

    # XDG portal for Wayland app integration
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    };

    # Wayland utilities
    environment.systemPackages = with pkgs; [
      wl-clipboard       # Clipboard (wl-copy, wl-paste)
      wl-clip-persist    # Keep clipboard after app closes
      wlr-randr          # Display configuration
      wayland-utils      # wayland-info
      xdg-utils          # xdg-open, etc.
    ];
  };
}
