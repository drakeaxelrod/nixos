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

    # KDE Wallet PAM integration - auto-unlock wallet on login
    security.pam.services = {
      sddm.kwallet.enable = true;
      login.kwallet.enable = true;
    };

    # Wayland defaults & compatibility
    programs.xwayland.enable = true;

    environment.sessionVariables = {
      # Wayland environment
      NIXOS_OZONE_WL = lib.mkIf config.modules.desktop.plasma.enableWaylandEnv "1";
      MOZ_ENABLE_WAYLAND = lib.mkIf config.modules.desktop.plasma.enableWaylandEnv "1";
      QT_QPA_PLATFORM = lib.mkIf config.modules.desktop.plasma.enableWaylandEnv "wayland";
      SDL_VIDEODRIVER = lib.mkIf config.modules.desktop.plasma.enableWaylandEnv "wayland,x11";  # Allow X11 fallback for Steam
      XDG_SESSION_TYPE = lib.mkIf config.modules.desktop.plasma.enableWaylandEnv "wayland";

      # StatusNotifier/AppIndicator support for GTK apps (virt-manager, etc.)
      XDG_CURRENT_DESKTOP = "KDE";  # Tell GTK apps we're on KDE

      # Fix screen locker losing Wayland session after suspend
      KSCREENLOCKER_GRACE_SECS = "5";
    };

    # Ensure screen locker works after suspend (prevent kscreenlocker disconnect)
    security.pam.services.kde-fingerprint = {};
    security.pam.services.kde = {};

    # XDG portals (screen sharing, file picker, etc.)
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
      # Prevent xdg-desktop-portal-gtk from loading — it crashes on KDE
      # and cascades into blueman, virt-manager, and other GTK apps dying
      xdgOpenUsePortal = true;
    };

    # Disable the GTK portal on KDE — KDE portal handles everything
    systemd.user.services.xdg-desktop-portal-gtk.enable = false;

    # Remove KDE bloat
    environment.plasma6.excludePackages =
      config.modules.desktop.plasma.excludePackages;

    # KDE utilities
    environment.systemPackages = with pkgs; [
      kdePackages.plasma-browser-integration
      kdePackages.kio-admin
      kdePackages.kio-extras
      kdePackages.ffmpegthumbs
      kdePackages.kwallet           # Credential storage
      kdePackages.kwalletmanager    # GUI to manage wallet
      kdePackages.kwallet-pam       # PAM integration

      # AppIndicator/StatusNotifier support for GTK system tray icons
      libdbusmenu
      libdbusmenu-gtk3
      libappindicator-gtk3
      libayatana-appindicator  # Modern ayatana fork used by many apps

      # System tools requiring polkit
      kdePackages.partitionmanager
      kdePackages.filelight

      # Wayland utilities
      wl-clipboard
      wl-clip-persist
      wlr-randr
      wayland-utils
      xdg-utils
    ];
  };
}
