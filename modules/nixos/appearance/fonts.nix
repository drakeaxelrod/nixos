# Fonts - System-wide font configuration
#
# Provides a comprehensive font setup with good defaults for:
# - General UI (Inter, Noto)
# - Programming (Nerd Fonts with ligatures and icons)
# - International support (CJK, emoji)
# - Document compatibility (Microsoft fonts, Liberation)
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.appearance.fonts;
in
{
  options.modules.appearance.fonts = {
    enable = lib.mkEnableOption "font configuration";

    defaultMonospace = lib.mkOption {
      type = lib.types.str;
      default = "Lilex Nerd Font Propo";
      description = "Default monospace font";
    };

    defaultSans = lib.mkOption {
      type = lib.types.str;
      default = "Inter";
      description = "Default sans-serif font";
    };
  };

  config = lib.mkIf cfg.enable {
    # Console font for TTY
    console = {
      font = "ter-v24b";
      packages = [ pkgs.terminus_font ];
      earlySetup = true;
    };

    fonts = {
      # Enable default font packages
      enableDefaultPackages = true;

      # Ghostscript fonts (URW fonts, Base-14 PostScript fonts)
      enableGhostscriptFonts = true;

      # Create /run/current-system/sw/share/X11/fonts
      fontDir.enable = true;

      # Fontconfig settings
      fontconfig = {
        enable = true;
        antialias = true;
        hinting = {
          enable = true;
          style = "slight";  # slight, medium, or full
        };
        subpixel = {
          rgba = "rgb";      # For standard LCD displays
          lcdfilter = "default";
        };

        # Default font families
        defaultFonts = {
          serif = [ "Noto Serif" "DejaVu Serif" ];
          sansSerif = [ cfg.defaultSans "Noto Sans" "DejaVu Sans" ];
          monospace = [ cfg.defaultMonospace "JetBrainsMono Nerd Font" "DejaVu Sans Mono" ];
          emoji = [ "Noto Color Emoji" "JoyPixels" ];
        };
      };

      # Font packages
      packages = with pkgs; [
        # === Sans-serif ===
        inter              # Modern UI font (used by many apps)
        noto-fonts         # Google's font family with broad language support

        # === Serif ===
        noto-fonts         # Includes Noto Serif
        dejavu_fonts       # Classic open-source fonts

        # === Monospace / Programming ===
        nerd-fonts.lilex           # Lilex with Nerd Font icons
        nerd-fonts.jetbrains-mono  # JetBrains Mono with Nerd Font icons
        nerd-fonts.fira-code       # Fira Code with ligatures and icons
        nerd-fonts.hack            # Hack font with icons

        # === CJK (Chinese, Japanese, Korean) ===
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif

        # === Emoji ===
        noto-fonts-color-emoji  # Google's color emoji font
        (joypixels.override { acceptLicense = true; })  # Alternative emoji font

        # === Microsoft compatibility ===
        corefonts          # Arial, Times New Roman, etc.
        liberation_ttf     # Liberation fonts (metric-compatible alternatives)
        carlito            # Open-source Calibri alternative
        caladea            # Open-source Cambria alternative

        # === Icons ===
        font-awesome       # Icon font for UI elements
        material-icons     # Google Material Design icons

        # === Symbols ===
        symbola            # Unicode symbols and pictographs
      ];
    };
  };
}
