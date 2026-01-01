# SDDM Display Manager
# System-level configuration for Simple Desktop Display Manager
# Can be used with Plasma or independently
#
# Available themes (check /run/current-system/sw/share/sddm/themes for installed):
#   - "breeze" (default, comes with Plasma)
#   - "sddm-astronaut-theme" (requires package: sddm-astronaut)
#   - "catppuccin-mocha" (requires package: catppuccin-sddm)
#   - "sugar-dark" (requires package: sddm-sugar-dark)
#   - "chili" (requires package: sddm-chili-theme)
#   - "elegant-sddm" (requires package: elegant-sddm)
#
# For sddm-astronaut-theme, use themeConfig to select a variant:
#   astronaut, black_hole, cyberpunk, hyprland_kath, japanese_aesthetic,
#   pixel_sakura, purple_leaves, post_apocalyptic, rust, etc.
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.desktop.sddm;

  # sddm-astronaut has built-in embeddedTheme parameter
  astronautPackage = pkgs.sddm-astronaut.override {
    embeddedTheme = cfg.themeConfig;
  };

  # Use overridden package if themeConfig is set, otherwise use provided package
  effectivePackage =
    if cfg.themePackage != null && cfg.themeConfig != null
    then astronautPackage
    else cfg.themePackage;
in
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
      description = "SDDM theme name (check /run/current-system/sw/share/sddm/themes)";
    };

    themePackage = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Package providing the SDDM theme (null for built-in themes like breeze)";
    };

    themeConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "japanese_aesthetic";
      description = "Theme variant (without .conf extension) for sddm-astronaut-theme";
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
      theme = cfg.theme;
      extraPackages = lib.mkIf (effectivePackage != null) [
        effectivePackage
        pkgs.kdePackages.qtmultimedia  # Required for video backgrounds
      ];
    };

    # Theme package must be in systemPackages to be symlinked to /run/current-system/sw/share/sddm/themes/
    environment.systemPackages = [
      pkgs.kdePackages.sddm-kcm  # KDE System Settings module for SDDM configuration
    ] ++ lib.optionals (effectivePackage != null) [
      effectivePackage
    ];

    # Configure theme settings
    environment.etc = lib.mkMerge [
      # Custom wallpaper override
      (lib.mkIf (cfg.wallpaper != null) {
        "sddm/themes/${cfg.theme}/theme.conf.user".text = ''
          [General]
          background=${cfg.wallpaper}
        '';
      })
    ];

    # Enable XWayland if using Wayland
    programs.xwayland.enable = lib.mkIf cfg.wayland true;
  };
}
