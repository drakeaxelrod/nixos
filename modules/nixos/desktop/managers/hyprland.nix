# Hyprland - Dynamic tiling Wayland compositor
# System-level configuration for Hyprland
{ config, lib, pkgs, inputs, ... }:

  imports = [
    inputs.hyprland.nixosModules.default
  ];

{
  options.modules.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland Wayland compositor";

    enableNvidiaPatches = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable NVIDIA-specific patches for Hyprland";
    };
  };

  config = lib.mkIf config.modules.desktop.hyprland.enable {
    # Enable Hyprland
    # Enable Hyprland from flake input
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };
    };

    # Wayland environment variables
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";          # Electron Wayland
      MOZ_ENABLE_WAYLAND = "1";      # Firefox Wayland
      QT_QPA_PLATFORM = "wayland";   # Qt Wayland
      SDL_VIDEODRIVER = "wayland";   # SDL Wayland
      XDG_SESSION_TYPE = "wayland";

      # Hyprland-specific
      WLR_NO_HARDWARE_CURSORS = lib.mkIf config.modules.desktop.hyprland.enableNvidiaPatches "1";
      LIBVA_DRIVER_NAME = lib.mkIf config.modules.desktop.hyprland.enableNvidiaPatches "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = lib.mkIf config.modules.desktop.hyprland.enableNvidiaPatches "nvidia";
    };

    # XDG portals for screen sharing, file picker, etc.
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    # Essential packages
    environment.systemPackages = with pkgs; [
      # Wayland utilities
      wl-clipboard
      wl-clip-persist
      wlr-randr
      wayland-utils
      xdg-utils

      # Hyprland ecosystem
      hyprpaper         # Wallpaper daemon
      hyprlock          # Screen locker
      hypridle          # Idle daemon
      hyprpicker        # Color picker

      # Notification daemon
      dunst

      # App launcher
      rofi-wayland

      # Status bar (optional - users can choose)
      waybar

      # Screenshot
      grim
      slurp

      # Terminal (recommended)
      kitty
    ];

    # Enable polkit for privilege escalation
    security.polkit.enable = true;

    # Fonts for UI
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      font-awesome
    ];
  };
}
