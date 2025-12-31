# GNOME Desktop Environment (Wayland)
{ config, lib, pkgs, ... }:

{
  options.modules.desktop.gnome = {
    enable = lib.mkEnableOption "GNOME desktop environment (Wayland)";

    enableWaylandEnv = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Wayland-related environment variables";
    };

    excludePackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        baobab
        cheese
        eog
        epiphany
        simple-scan
        totem
        yelp
        evince
        file-roller
        geary
        seahorse
        gnome-tour
        gnome-calculator
        gnome-calendar
        gnome-characters
        gnome-clocks
        gnome-contacts
        gnome-font-viewer
        gnome-logs
        gnome-maps
        gnome-music
        gnome-photos
        gnome-screenshot
        gnome-system-monitor
        gnome-weather
        gnome-disk-utility
        gnome-connections
      ];
      description = "GNOME packages to exclude (debloating)";
    };
  };

  config = lib.mkIf config.modules.desktop.gnome.enable {
    # X11 is still required for GDM, even on Wayland
    services.xserver = {
      enable = true;
      excludePackages = [ pkgs.xterm ];
    };

    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    # Wayland defaults & compatibility
    programs.xwayland.enable = true;

    environment.sessionVariables = lib.mkIf config.modules.desktop.gnome.enableWaylandEnv {
      NIXOS_OZONE_WL = "1";          # Electron Wayland
      MOZ_ENABLE_WAYLAND = "1";      # Firefox Wayland
      QT_QPA_PLATFORM = "wayland";   # Qt Wayland
      SDL_VIDEODRIVER = "wayland";   # SDL Wayland
      XDG_SESSION_TYPE = "wayland";
    };

    # XDG portals (screen sharing, file picker, etc.)
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    };

    # Remove GNOME bloat
    environment.gnome.excludePackages =
      config.modules.desktop.gnome.excludePackages;

    # GNOME services
    services.gnome.gnome-remote-desktop.enable = true;

    # GNOME extensions & Wayland utilities
    environment.systemPackages = with pkgs; [
      gnome-extension-manager
      gnomeExtensions.appindicator
      gnomeExtensions.dash-to-dock
      gnome-tweaks
      gnome-remote-desktop

      # Wayland utilities
      wl-clipboard
      wl-clip-persist
      wlr-randr
      wayland-utils
      xdg-utils
    ];
  };
}
