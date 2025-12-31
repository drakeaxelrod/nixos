# GNOME Desktop Environment on Wayland
{ config, pkgs, lib, ... }:

{
  services.xserver.enable = true;
  services.xserver.excludePackages = [ pkgs.xterm ];
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Wayland environment variables
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";         # Electron apps use Wayland
    MOZ_ENABLE_WAYLAND = "1";     # Firefox Wayland
    QT_QPA_PLATFORM = "wayland";  # Qt apps use Wayland
    SDL_VIDEODRIVER = "wayland";  # SDL games use Wayland
    XDG_SESSION_TYPE = "wayland";
  };

  programs.xwayland.enable = true;

  # XDG portal for screen sharing, file picker, etc.
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  # Remove GNOME bloat
  environment.gnome.excludePackages = with pkgs; [
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

  services.gnome.gnome-remote-desktop.enable = true;

  # GNOME packages
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
}
