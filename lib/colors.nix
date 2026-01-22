# Color Palettes for NixOS Configuration
# Centralized color definitions for use across NixOS and Home Manager configurations
#
# Usage in modules:
#   { lib, ... }:
#   let
#     colors = lib.colors;           # Uses default palette (onedarkpro)
#     odp = lib.colors.palettes.onedarkpro;  # Explicit palette access
#   in
#   {
#     someOption = colors.hex.bg0;           # "#16191d"
#     someRgb = colors.rgb.bg0;              # "22,25,29"
#     someRgba = colors.rgba.bg0 0.85;       # "rgba(22, 25, 29, 0.85)"
#   }
#
# To add a new palette:
#   1. Add the palette definition to `palettes` below
#   2. Optionally set it as default by changing `defaultPalette`
#
{ lib }:

let
  # ===========================================================================
  # Palette Definitions
  # ===========================================================================
  # Each palette defines colors as RGB { r, g, b } attrsets
  # All palettes should have the same structure for interchangeability

  palettes = {
    # -------------------------------------------------------------------------
    # OneDark Pro - Atom-inspired dark theme
    # -------------------------------------------------------------------------
    onedarkpro = {
      # Background shades (darkest to lightest)
      bg0 = { r = 22; g = 25; b = 29; };      # #16191d - Main background
      bg1 = { r = 30; g = 34; b = 39; };      # #1e2227 - Secondary background
      bg2 = { r = 44; g = 49; b = 58; };      # #2c313a - Elevated surfaces
      bg3 = { r = 62; g = 68; b = 81; };      # #3e4451 - Borders, separators

      # Foreground shades (dimmest to brightest)
      fg0 = { r = 107; g = 113; b = 125; };   # #6b717d - Muted/inactive text
      fg1 = { r = 171; g = 178; b = 191; };   # #abb2bf - Normal text
      fg2 = { r = 215; g = 218; b = 224; };   # #d7dae0 - Bright/emphasized text

      # Accent colors
      red = { r = 224; g = 108; b = 117; };       # #e06c75
      green = { r = 152; g = 195; b = 121; };     # #98c379
      yellow = { r = 209; g = 154; b = 102; };    # #d19a66
      blue = { r = 97; g = 175; b = 239; };       # #61afef
      purple = { r = 198; g = 120; b = 221; };    # #c678dd
      cyan = { r = 86; g = 182; b = 194; };       # #56b6c2
      orange = { r = 209; g = 154; b = 102; };    # #d19a66
      magenta = { r = 193; g = 98; b = 222; };    # #c162de

      # Terminal colors (ANSI)
      black = { r = 63; g = 68; b = 81; };        # #3f4451
      blackBright = { r = 79; g = 86; b = 102; }; # #4f5666
      redBright = { r = 255; g = 97; b = 110; };  # #ff616e
      greenBright = { r = 165; g = 224; b = 117; }; # #a5e075
      yellowBright = { r = 240; g = 164; b = 93; }; # #f0a45d
      blueBright = { r = 77; g = 196; b = 255; }; # #4dc4ff
      purpleBright = { r = 222; g = 115; b = 255; }; # #de73ff
      cyanBright = { r = 76; g = 209; b = 224; }; # #4cd1e0
      white = { r = 215; g = 218; b = 224; };     # #d7dae0
      whiteBright = { r = 230; g = 230; b = 230; }; # #e6e6e6
    };

    # -------------------------------------------------------------------------
    # Catppuccin Mocha - Warm pastel dark theme
    # -------------------------------------------------------------------------
    catppuccin-mocha = {
      bg0 = { r = 30; g = 30; b = 46; };      # #1e1e2e - Base
      bg1 = { r = 49; g = 50; b = 68; };      # #313244 - Surface0
      bg2 = { r = 69; g = 71; b = 90; };      # #45475a - Surface1
      bg3 = { r = 88; g = 91; b = 112; };     # #585b70 - Surface2

      fg0 = { r = 166; g = 173; b = 200; };   # #a6adc8 - Subtext0
      fg1 = { r = 186; g = 194; b = 222; };   # #bac2de - Subtext1
      fg2 = { r = 205; g = 214; b = 244; };   # #cdd6f4 - Text

      red = { r = 243; g = 139; b = 168; };       # #f38ba8
      green = { r = 166; g = 227; b = 161; };     # #a6e3a1
      yellow = { r = 249; g = 226; b = 175; };    # #f9e2af
      blue = { r = 137; g = 180; b = 250; };      # #89b4fa
      purple = { r = 203; g = 166; b = 247; };    # #cba6f7 - Mauve
      cyan = { r = 148; g = 226; b = 213; };      # #94e2d5 - Teal
      orange = { r = 250; g = 179; b = 135; };    # #fab387 - Peach
      magenta = { r = 245; g = 194; b = 231; };   # #f5c2e7 - Pink

      black = { r = 69; g = 71; b = 90; };        # #45475a
      blackBright = { r = 88; g = 91; b = 112; }; # #585b70
      redBright = { r = 243; g = 139; b = 168; }; # #f38ba8
      greenBright = { r = 166; g = 227; b = 161; }; # #a6e3a1
      yellowBright = { r = 249; g = 226; b = 175; }; # #f9e2af
      blueBright = { r = 137; g = 180; b = 250; }; # #89b4fa
      purpleBright = { r = 203; g = 166; b = 247; }; # #cba6f7
      cyanBright = { r = 148; g = 226; b = 213; }; # #94e2d5
      white = { r = 186; g = 194; b = 222; };     # #bac2de
      whiteBright = { r = 205; g = 214; b = 244; }; # #cdd6f4
    };

    # -------------------------------------------------------------------------
    # Dracula - Purple-accented dark theme
    # -------------------------------------------------------------------------
    dracula = {
      bg0 = { r = 40; g = 42; b = 54; };      # #282a36 - Background
      bg1 = { r = 68; g = 71; b = 90; };      # #44475a - Current Line
      bg2 = { r = 68; g = 71; b = 90; };      # #44475a - Selection
      bg3 = { r = 98; g = 114; b = 164; };    # #6272a4 - Comment

      fg0 = { r = 98; g = 114; b = 164; };    # #6272a4 - Comment
      fg1 = { r = 248; g = 248; b = 242; };   # #f8f8f2 - Foreground
      fg2 = { r = 255; g = 255; b = 255; };   # #ffffff - Bright

      red = { r = 255; g = 85; b = 85; };         # #ff5555
      green = { r = 80; g = 250; b = 123; };      # #50fa7b
      yellow = { r = 241; g = 250; b = 140; };    # #f1fa8c
      blue = { r = 139; g = 233; b = 253; };      # #8be9fd - Cyan
      purple = { r = 189; g = 147; b = 249; };    # #bd93f9
      cyan = { r = 139; g = 233; b = 253; };      # #8be9fd
      orange = { r = 255; g = 184; b = 108; };    # #ffb86c
      magenta = { r = 255; g = 121; b = 198; };   # #ff79c6 - Pink

      black = { r = 40; g = 42; b = 54; };        # #282a36
      blackBright = { r = 68; g = 71; b = 90; };  # #44475a
      redBright = { r = 255; g = 110; b = 110; }; # #ff6e6e
      greenBright = { r = 105; g = 255; b = 148; }; # #69ff94
      yellowBright = { r = 255; g = 255; b = 165; }; # #ffffa5
      blueBright = { r = 164; g = 255; b = 255; }; # #a4ffff
      purpleBright = { r = 214; g = 172; b = 255; }; # #d6acff
      cyanBright = { r = 164; g = 255; b = 255; }; # #a4ffff
      white = { r = 248; g = 248; b = 242; };     # #f8f8f2
      whiteBright = { r = 255; g = 255; b = 255; }; # #ffffff
    };

    # -------------------------------------------------------------------------
    # Nord - Arctic, bluish dark theme
    # -------------------------------------------------------------------------
    nord = {
      bg0 = { r = 46; g = 52; b = 64; };      # #2e3440 - Polar Night
      bg1 = { r = 59; g = 66; b = 82; };      # #3b4252
      bg2 = { r = 67; g = 76; b = 94; };      # #434c5e
      bg3 = { r = 76; g = 86; b = 106; };     # #4c566a

      fg0 = { r = 216; g = 222; b = 233; };   # #d8dee9 - Snow Storm
      fg1 = { r = 229; g = 233; b = 240; };   # #e5e9f0
      fg2 = { r = 236; g = 239; b = 244; };   # #eceff4

      red = { r = 191; g = 97; b = 106; };        # #bf616a - Aurora
      green = { r = 163; g = 190; b = 140; };     # #a3be8c
      yellow = { r = 235; g = 203; b = 139; };    # #ebcb8b
      blue = { r = 129; g = 161; b = 193; };      # #81a1c1 - Frost
      purple = { r = 180; g = 142; b = 173; };    # #b48ead
      cyan = { r = 136; g = 192; b = 208; };      # #88c0d0
      orange = { r = 208; g = 135; b = 112; };    # #d08770
      magenta = { r = 180; g = 142; b = 173; };   # #b48ead

      black = { r = 59; g = 66; b = 82; };        # #3b4252
      blackBright = { r = 76; g = 86; b = 106; }; # #4c566a
      redBright = { r = 191; g = 97; b = 106; };  # #bf616a
      greenBright = { r = 163; g = 190; b = 140; }; # #a3be8c
      yellowBright = { r = 235; g = 203; b = 139; }; # #ebcb8b
      blueBright = { r = 129; g = 161; b = 193; }; # #81a1c1
      purpleBright = { r = 180; g = 142; b = 173; }; # #b48ead
      cyanBright = { r = 143; g = 188; b = 187; }; # #8fbcbb
      white = { r = 229; g = 233; b = 240; };     # #e5e9f0
      whiteBright = { r = 236; g = 239; b = 244; }; # #eceff4
    };

    # -------------------------------------------------------------------------
    # Gruvbox Dark - Retro groove dark theme
    # -------------------------------------------------------------------------
    gruvbox-dark = {
      bg0 = { r = 40; g = 40; b = 40; };      # #282828
      bg1 = { r = 60; g = 56; b = 54; };      # #3c3836
      bg2 = { r = 80; g = 73; b = 69; };      # #504945
      bg3 = { r = 102; g = 92; b = 84; };     # #665c54

      fg0 = { r = 168; g = 153; b = 132; };   # #a89984
      fg1 = { r = 235; g = 219; b = 178; };   # #ebdbb2
      fg2 = { r = 251; g = 241; b = 199; };   # #fbf1c7

      red = { r = 251; g = 73; b = 52; };         # #fb4934
      green = { r = 184; g = 187; b = 38; };      # #b8bb26
      yellow = { r = 250; g = 189; b = 47; };     # #fabd2f
      blue = { r = 131; g = 165; b = 152; };      # #83a598
      purple = { r = 211; g = 134; b = 155; };    # #d3869b
      cyan = { r = 142; g = 192; b = 124; };      # #8ec07c
      orange = { r = 254; g = 128; b = 25; };     # #fe8019
      magenta = { r = 211; g = 134; b = 155; };   # #d3869b

      black = { r = 40; g = 40; b = 40; };        # #282828
      blackBright = { r = 146; g = 131; b = 116; }; # #928374
      redBright = { r = 251; g = 73; b = 52; };   # #fb4934
      greenBright = { r = 184; g = 187; b = 38; }; # #b8bb26
      yellowBright = { r = 250; g = 189; b = 47; }; # #fabd2f
      blueBright = { r = 131; g = 165; b = 152; }; # #83a598
      purpleBright = { r = 211; g = 134; b = 155; }; # #d3869b
      cyanBright = { r = 142; g = 192; b = 124; }; # #8ec07c
      white = { r = 235; g = 219; b = 178; };     # #ebdbb2
      whiteBright = { r = 251; g = 241; b = 199; }; # #fbf1c7
    };
  };

  # ===========================================================================
  # Default Palette Selection
  # ===========================================================================
  defaultPalette = "onedarkpro";

  # ===========================================================================
  # Color Conversion Helpers
  # ===========================================================================

  # Convert RGB to hex string
  rgbToHex = { r, g, b }:
    let
      toHex = n:
        let hex = lib.toHexString n;
        in if builtins.stringLength hex == 1 then "0${hex}" else hex;
    in "#${toHex r}${toHex g}${toHex b}";

  # Convert RGB to comma-separated string
  rgbToString = { r, g, b }: "${toString r},${toString g},${toString b}";

  # Convert RGB to CSS rgba() with alpha
  rgbToRgba = { r, g, b }: alpha:
    "rgba(${toString r}, ${toString g}, ${toString b}, ${toString alpha})";

  # Convert RGB to KDE-style RGB string
  rgbToKde = { r, g, b }: "${toString r},${toString g},${toString b}";

  # ===========================================================================
  # Build Color Formats for a Palette
  # ===========================================================================

  mkColorFormats = palette: {
    # Raw palette (RGB values as attrset)
    inherit palette;

    # Hex colors (e.g., "#16191d")
    hex = lib.mapAttrs (_: rgbToHex) palette;

    # RGB strings (e.g., "22,25,29")
    rgb = lib.mapAttrs (_: rgbToString) palette;

    # RGBA functions (e.g., colors.rgba.bg0 0.85 => "rgba(22, 25, 29, 0.85)")
    rgba = lib.mapAttrs (_: color: rgbToRgba color) palette;

    # KDE-style RGB (same as rgb, for KDE configs)
    kde = lib.mapAttrs (_: rgbToKde) palette;

    # Semantic aliases
    semantic = let hex = lib.mapAttrs (_: rgbToHex) palette; in {
      background = hex.bg0;
      backgroundAlt = hex.bg1;
      surface = hex.bg2;
      border = hex.bg3;
      text = hex.fg1;
      textMuted = hex.fg0;
      textBright = hex.fg2;
      error = hex.red;
      warning = hex.yellow;
      success = hex.green;
      info = hex.blue;
      accent = hex.blue;
      link = hex.blue;
      focus = hex.blue;
    };
  };

  # Build color formats for all palettes
  formattedPalettes = lib.mapAttrs (_: mkColorFormats) palettes;

  # Get the default palette's formats
  defaultFormats = formattedPalettes.${defaultPalette};

in
# Export default palette's formats at top level, plus access to all palettes
defaultFormats // {
  # Access to all defined palettes
  palettes = formattedPalettes;

  # Currently active palette name
  current = defaultPalette;

  # Helper to switch palettes (returns the formatted palette)
  use = name:
    if builtins.hasAttr name formattedPalettes
    then formattedPalettes.${name}
    else throw "Unknown color palette: ${name}. Available: ${builtins.concatStringsSep ", " (builtins.attrNames palettes)}";

  # Helper functions for custom color manipulation
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
