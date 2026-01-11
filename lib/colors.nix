# OneDark Pro Color Palette
# Centralized color definitions for use across NixOS and Home Manager configurations
#
# Usage in modules:
#   { lib, ... }:
#   let colors = lib.colors; in
#   {
#     someOption = colors.hex.bg0;           # "#16191d"
#     someRgb = colors.rgb.bg0;              # "22,25,29"
#     someRgba = colors.rgba.bg0 0.85;       # "rgba(22, 25, 29, 0.85)"
#   }
#
{ lib }:

let
  # Base color definitions (RGB values)
  # Derived from OneDark Pro VSCode theme and KDE color scheme
  palette = {
    # Background shades (darkest to lightest)
    bg0 = { r = 22; g = 25; b = 29; };      # #16191d - Main background
    bg1 = { r = 30; g = 34; b = 39; };      # #1e2227 - Secondary background
    bg2 = { r = 44; g = 49; b = 58; };      # #2c313a - Elevated surfaces
    bg3 = { r = 62; g = 68; b = 81; };      # #3e4451 - Borders, separators

    # Foreground shades (dimmest to brightest)
    fg0 = { r = 107; g = 113; b = 125; };   # #6b717d - Muted/inactive text
    fg1 = { r = 171; g = 178; b = 191; };   # #abb2bf - Normal text
    fg2 = { r = 215; g = 218; b = 224; };   # #d7dae0 - Bright/emphasized text

    # Accent colors (syntax highlighting / UI accents)
    red = { r = 224; g = 108; b = 117; };       # #e06c75 - Errors, deletions
    green = { r = 152; g = 195; b = 121; };     # #98c379 - Success, additions
    yellow = { r = 209; g = 154; b = 102; };    # #d19a66 - Warnings, modified
    blue = { r = 97; g = 175; b = 239; };       # #61afef - Info, links, focus
    purple = { r = 198; g = 120; b = 221; };    # #c678dd - Keywords, special
    cyan = { r = 86; g = 182; b = 194; };       # #56b6c2 - Constants, types

    # Extended palette
    orange = { r = 209; g = 154; b = 102; };    # #d19a66 - Same as yellow (OneDark style)
    magenta = { r = 193; g = 98; b = 222; };    # #c162de - Alternate purple

    # Terminal colors (ANSI)
    black = { r = 63; g = 68; b = 81; };        # #3f4451 - ANSI black
    blackBright = { r = 79; g = 86; b = 102; }; # #4f5666 - ANSI bright black
    redBright = { r = 255; g = 97; b = 110; };  # #ff616e
    greenBright = { r = 165; g = 224; b = 117; }; # #a5e075
    yellowBright = { r = 240; g = 164; b = 93; }; # #f0a45d
    blueBright = { r = 77; g = 196; b = 255; }; # #4dc4ff
    purpleBright = { r = 222; g = 115; b = 255; }; # #de73ff
    cyanBright = { r = 76; g = 209; b = 224; }; # #4cd1e0
    white = { r = 215; g = 218; b = 224; };     # #d7dae0
    whiteBright = { r = 230; g = 230; b = 230; }; # #e6e6e6
  };

  # Convert RGB to hex string
  rgbToHex = { r, g, b }: let
    toHex = n:
      let
        hex = lib.toHexString n;
      in
        if builtins.stringLength hex == 1 then "0${hex}" else hex;
  in
    "#${toHex r}${toHex g}${toHex b}";

  # Convert RGB to comma-separated string
  rgbToString = { r, g, b }: "${toString r},${toString g},${toString b}";

  # Convert RGB to CSS rgba() with alpha
  rgbToRgba = { r, g, b }: alpha:
    "rgba(${toString r}, ${toString g}, ${toString b}, ${toString alpha})";

  # Convert RGB to KDE-style RGB string with spaces
  rgbToKde = { r, g, b }: "${toString r},${toString g},${toString b}";

  # Build hex color attrset
  hexColors = lib.mapAttrs (_: rgbToHex) palette;

  # Build RGB string attrset
  rgbColors = lib.mapAttrs (_: rgbToString) palette;

  # Build RGBA function attrset (each value is a function that takes alpha)
  rgbaColors = lib.mapAttrs (_: color: rgbToRgba color) palette;

  # Build KDE-style RGB attrset
  kdeColors = lib.mapAttrs (_: rgbToKde) palette;

in
{
  # Raw palette (RGB values as attrset)
  inherit palette;

  # Hex colors (e.g., "#16191d")
  hex = hexColors;

  # RGB strings (e.g., "22,25,29")
  rgb = rgbColors;

  # RGBA functions (e.g., colors.rgba.bg0 0.85 => "rgba(22, 25, 29, 0.85)")
  rgba = rgbaColors;

  # KDE-style RGB (same as rgb, but explicit for KDE configs)
  kde = kdeColors;

  # Semantic aliases for common use cases
  semantic = {
    # Backgrounds
    background = hexColors.bg0;
    backgroundAlt = hexColors.bg1;
    surface = hexColors.bg2;
    border = hexColors.bg3;

    # Text
    text = hexColors.fg1;
    textMuted = hexColors.fg0;
    textBright = hexColors.fg2;

    # Status
    error = hexColors.red;
    warning = hexColors.yellow;
    success = hexColors.green;
    info = hexColors.blue;

    # Accent
    accent = hexColors.blue;
    link = hexColors.blue;
    focus = hexColors.blue;
  };

  # Helper functions for custom conversions
  helpers = {
    inherit rgbToHex rgbToString rgbToRgba rgbToKde;

    # Lighten a color by percentage (0-100)
    lighten = { r, g, b }: percent:
      let
        factor = 1 + (percent / 100.0);
        clamp = n: if n > 255 then 255 else (if n < 0 then 0 else builtins.floor n);
      in {
        r = clamp (r * factor);
        g = clamp (g * factor);
        b = clamp (b * factor);
      };

    # Darken a color by percentage (0-100)
    darken = { r, g, b }: percent:
      let
        factor = 1 - (percent / 100.0);
        clamp = n: if n > 255 then 255 else (if n < 0 then 0 else builtins.floor n);
      in {
        r = clamp (r * factor);
        g = clamp (g * factor);
        b = clamp (b * factor);
      };

    # Set alpha on a color (returns rgba string)
    withAlpha = color: alpha: rgbToRgba color alpha;
  };
}
