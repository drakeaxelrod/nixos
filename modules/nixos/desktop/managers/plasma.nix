# KDE Plasma Desktop Environment
# System-level configuration for KDE Plasma desktop
# NOTE: SDDM is now a separate module (modules.desktop.sddm)
{ config, lib, pkgs, ... }:

{
  options.modules.desktop.plasma = {
    enable = lib.mkEnableOption "KDE Plasma desktop environment";

    enableWaylandEnv = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Wayland-related environment variables";
    };

    excludePackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs.kdePackages; [
        elisa
        gwenview
        okular
        kate
        khelpcenter
      ];
      description = "KDE packages to exclude (debloating)";
    };
  };

  config = lib.mkIf config.modules.desktop.plasma.enable {
    # Enable Plasma desktop manager
    services.desktopManager.plasma6.enable = true;

    # Wayland defaults & compatibility
    programs.xwayland.enable = true;

    environment.sessionVariables = lib.mkIf config.modules.desktop.plasma.enableWaylandEnv {
      NIXOS_OZONE_WL = "1";          # Electron Wayland
      MOZ_ENABLE_WAYLAND = "1";      # Firefox Wayland
      QT_QPA_PLATFORM = "wayland";   # Qt Wayland
      SDL_VIDEODRIVER = "wayland";   # SDL Wayland
      XDG_SESSION_TYPE = "wayland";
    };

    # XDG portals (screen sharing, file picker, etc.)
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    };

    # Remove KDE bloat
    environment.plasma6.excludePackages =
      config.modules.desktop.plasma.excludePackages;

    # KDE utilities
    environment.systemPackages = with pkgs; [
      kdePackages.plasma-browser-integration
      kdePackages.kio-admin
      kdePackages.kio-extras
      kdePackages.ffmpegthumbs

      # AppIndicator support for system tray icons (StatusNotifier)
      libdbusmenu
      libdbusmenu-gtk3
      libappindicator-gtk3

      # Wayland utilities
      wl-clipboard
      wl-clip-persist
      wlr-randr
      wayland-utils
      xdg-utils
    ];
  };
}
