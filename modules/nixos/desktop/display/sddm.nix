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
#   onedark_custom (custom OneDark Pro theme with custom wallpaper)
#   astronaut, black_hole, cyberpunk, hyprland_kath, japanese_aesthetic,
#   pixel_sakura, purple_leaves, post_apocalyptic, rust, etc.
{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.modules.desktop.sddm;

  # Custom OneDark Pro theme config for sddm-astronaut
  # Based on japanese_aesthetic layout with OneDark Pro colors and custom wallpaper
  onedarkCustomConfig = pkgs.writeText "onedark_custom.conf" ''
    [General]
    ScreenWidth="1920"
    ScreenHeight="1080"
    ScreenPadding=""
    Font="Inter"
    FontSize="14"
    KeyboardSize="0.4"
    RoundCorners="20"
    Locale=""
    HourFormat="HH:mm"
    DateFormat="dddd, MMMM d"
    HeaderText=""

    # Custom wallpaper
    Background="${cfg.wallpaper}"
    BackgroundPlaceholder=""
    BackgroundSpeed=""
    PauseBackground=""
    DimBackground="0.3"
    CropBackground="true"
    BackgroundHorizontalAlignment="center"
    BackgroundVerticalAlignment="center"

    # Colors (OneDark Pro)
    # Background: #282c34, Foreground: #abb2bf
    # Red: #e06c75, Green: #98c379, Yellow: #e5c07b
    # Blue: #61afef, Magenta: #c678dd, Cyan: #56b6c2
    # Comment: #5c6370, Selection: #3e4451

    # Header/Clock - light text for visibility
    HeaderTextColor="#abb2bf"
    DateTextColor="#abb2bf"
    TimeTextColor="#ffffff"

    # Form background with transparency (semi-transparent dark)
    FormBackgroundColor="#282c34E6"
    BackgroundColor="#282c34"
    DimBackgroundColor="#1e2127"

    # Input fields - selection color background, light text
    LoginFieldBackgroundColor="#3e4451"
    PasswordFieldBackgroundColor="#3e4451"
    LoginFieldTextColor="#abb2bf"
    PasswordFieldTextColor="#abb2bf"

    # Icons - blue accent
    UserIconColor="#61afef"
    PasswordIconColor="#61afef"

    # Placeholder and warnings
    PlaceholderTextColor="#5c6370"
    WarningColor="#e06c75"

    # Login button - green accent with dark text
    LoginButtonTextColor="#1e2127"
    LoginButtonBackgroundColor="#98c379"

    # System buttons (power, restart, etc)
    SystemButtonsIconsColor="#abb2bf"
    SessionButtonTextColor="#abb2bf"
    VirtualKeyboardButtonTextColor="#abb2bf"

    # Dropdowns
    DropdownTextColor="#abb2bf"
    DropdownSelectedBackgroundColor="#61afef"
    DropdownBackgroundColor="#3e4451"

    # Highlights/Selection
    HighlightTextColor="#1e2127"
    HighlightBackgroundColor="#61afef"
    HighlightBorderColor="#61afef"

    # Hover states - cyan for interactive feedback
    HoverUserIconColor="#56b6c2"
    HoverPasswordIconColor="#56b6c2"
    HoverSystemButtonsIconsColor="#98c379"
    HoverSessionButtonTextColor="#61afef"
    HoverVirtualKeyboardButtonTextColor="#61afef"

    # Form - enable background with blur
    PartialBlur="true"
    FullBlur="false"
    BlurMax="48"
    Blur="2.0"
    HaveFormBackground="true"
    FormPosition="left"
    VirtualKeyboardPosition="left"

    # Interface
    HideVirtualKeyboard="false"
    HideSystemButtons="false"
    HideLoginButton="false"
    ForceLastUser="true"
    PasswordFocus="true"
    HideCompletePassword="true"
    AllowEmptyPassword="false"
    AllowUppercaseLettersInUsernames="false"
    BypassSystemButtonsChecks="false"
    RightToLeftLayout="false"
  '';

  # sddm-astronaut with custom OneDark theme
  # The theme reads config from Themes/<name>.conf, referenced in metadata.desktop
  # Note: sddm-astronaut uses installPhase directly (no build phases), so we override that
  astronautOnedark = pkgs.sddm-astronaut.overrideAttrs (old: {
    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/sddm/themes/sddm-astronaut-theme
      cp -r $src/* $out/share/sddm/themes/sddm-astronaut-theme

      # Ensure we have write permissions to modify files
      chmod -R u+w $out/share/sddm/themes/sddm-astronaut-theme

      # Add our custom OneDark Pro config to Themes directory
      cp ${onedarkCustomConfig} $out/share/sddm/themes/sddm-astronaut-theme/Themes/onedark_custom.conf

      # Update metadata.desktop to use our custom config
      sed -i 's|ConfigFile=Themes/.*\.conf|ConfigFile=Themes/onedark_custom.conf|' \
        $out/share/sddm/themes/sddm-astronaut-theme/metadata.desktop

      runHook postInstall
    '';
  });

  # sddm-astronaut with built-in embeddedTheme parameter
  astronautBuiltin = pkgs.sddm-astronaut.override {
    embeddedTheme = cfg.themeConfig;
  };

  # Determine which package to use based on themeConfig
  effectivePackage =
    if cfg.themePackage != null && cfg.themeConfig == "onedark_custom"
    then astronautOnedark
    else if cfg.themePackage != null && cfg.themeConfig != null
    then astronautBuiltin
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
      example = "onedark_custom";
      description = ''
        Theme variant for sddm-astronaut-theme.
        Use "onedark_custom" for custom OneDark Pro theme with custom wallpaper.
        Other options: astronaut, black_hole, cyberpunk, japanese_aesthetic, etc.
      '';
    };

    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = "${inputs.self}/assets/wallpapers/nix-wallpaper-binary-red_8k.png";
      description = "Path to wallpaper image (only used with onedark_custom theme)";
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

    # Enable XWayland if using Wayland
    programs.xwayland.enable = lib.mkIf cfg.wayland true;
  };
}
